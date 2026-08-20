'use strict';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';
import Gvc from 'gi://Gvc';
import * as Volume from 'resource:///org/gnome/shell/ui/status/volume.js';

import {createLogger} from './logger.js';

const MEDIA_PLAYER_PREFIX = 'org.mpris.MediaPlayer2.';

export const MediaController = GObject.registerClass({
    GTypeName: 'BluetoothBatteryMeter_MediaController',
    Properties: {
        'output-is-a2dp': GObject.ParamSpec.boolean(
            'output-is-a2dp', 'output-is-a2dp', '', GObject.ParamFlags.READWRITE, false
        ),
    },
}, class MediaController extends GObject.Object {
    _init(settings, devicePath, previousOnDestroyVolume) {
        super._init();
        this._log = createLogger('MediaController');
        this._settings = settings;
        this._devicePath = devicePath;
        this._noSymbolMac = devicePath.substring(devicePath.indexOf('dev_') + 4)
            .replace(/_/g, '').toUpperCase();

        this._controllerReady = false;
        this._previousVolume = previousOnDestroyVolume;
        this._sink = null;
        this._defaultSinkChangedId = null;
        this._stateId = null;
        this._volumeId = null;
        this._muteId = null;

        this._mprisNames = null;
        this._lastPausedPlayer = null;
        this._playbackStatusChangePending = false;

        this._control = Volume.getMixerControl();
        if (!this._control)
            return;

        if (this._control.get_state() === Gvc.MixerControlState.READY) {
            this._onControlReady();
            this._controllerReady = true;
        } else {
            this._controllerReady = false;
        }

        this._stateChangeId = this._control.connect('state-changed', () => {
            if (this._control.get_state() === Gvc.MixerControlState.READY) {
                this._onControlReady();
                this._controllerReady = true;
            } else {
                this._disconnectController();
                this._controllerReady = false;
            }
        });
    }

    _monitorSinkVolume() {
        this._volumeId = this._sink?.connect('notify::volume', () => {
            this._previousVolume = -1;
        });
    }

    _initializeSink(sink) {
        if (this._sink === sink)
            return;

        this._unmonitorSink();

        this._sink = sink;

        if (sink.get_state() === Gvc.MixerStreamState.RUNNING)
            this._sinkStateIsRunning = true;
        else
            this._sinkStateIsRunning = false;


        this._sinkIsMuted = this._sink.get_is_muted();

        this._stateId = sink.connect('notify::state', () => {
            const state = this._sink.get_state();
            if (state === Gvc.MixerStreamState.RUNNING)
                this._sinkStateIsRunning = true;
            else
                this._sinkStateIsRunning = false;
        });

        this._muteId = sink.connect('notify::is-muted', () => {
            this._sinkIsMuted = this._sink.get_is_muted();

            if (this._sinkIsMuted) {
                if (this._previousVolume >= 0) {
                    this._sink.set_volume(this._previousVolume);
                    this._sink.push_volume();
                    this._previousVolume = -1;
                }
            }
        });

        this._monitorSinkVolume();
    }

    _unmonitorSinkVolume() {
        if (this._volumeId) {
            this._sink.disconnect(this._volumeId);
            this._volumeId = null;
        }
    }

    _unmonitorSink() {
        if (!this._sink)
            return;

        if (this._stateId) {
            this._sink.disconnect(this._stateId);
            this._stateId = null;
        }

        if (this._muteId) {
            this._sink.disconnect(this._muteId);
            this._muteId = null;
        }
        this._unmonitorSinkVolume();

        this._sink = null;
    }

    _findA2dpSinkForMac() {
        const sinks = this._control.get_sinks();
        for (const sink of sinks) {
            const name = sink.get_name() || '';
            const noSymbolName = name.replace(/[_\-.:]/g, '').toUpperCase();
            if (!noSymbolName.includes(this._noSymbolMac))
                continue;
            const device = this._control.lookup_device_from_stream(sink);
            // PipeWire names the A2DP sink profile per negotiated codec, e.g.
            // 'a2dp-sink' (AAC), 'a2dp-sink-sbc', 'a2dp-sink-sbc_xq',
            // 'a2dp-sink-aptx', 'a2dp-sink-ldac'. Match the family prefix so
            // playback control works regardless of the active codec.
            if (device?.get_active_profile()?.startsWith('a2dp-sink'))
                return sink;
        }
        return null;
    }

    _checkAndMonitorSink() {
        const defaultSink = this._control.get_default_sink();
        const a2dpSink = this._findA2dpSinkForMac();

        if (defaultSink && a2dpSink && defaultSink === a2dpSink) {
            this.output_is_a2dp = true;
            this.notify('output-is-a2dp');
            this._initializeSink(a2dpSink);
        } else {
            this.output_is_a2dp = false;
            this.notify('output-is-a2dp');
            this._unmonitorSink();
        }
    }

    _onControlReady() {
        if (this._defaultSinkChangedId)
            this._control.disconnect(this._defaultSinkChangedId);

        this._defaultSinkChangedId = this._control.connect('default-sink-changed', () => {
            this._checkAndMonitorSink();
        });
        this._checkAndMonitorSink();
    }

    _disconnectController() {
        this._unmonitorSink();
        if (this._defaultSinkChangedId)
            this._control.disconnect(this._defaultSinkChangedId);
        this._defaultSinkChangedId = null;
    }

    setConversationAwarenessVolume(attenuated, caVolume) {
        if (!this._controllerReady || !this._sink || !this._sinkStateIsRunning || this._sinkIsMuted)
            return;

        if (this._attenuated === attenuated)
            return;

        this._attenuated = attenuated;

        if (attenuated && this._previousVolume >= 0)
            return;

        if (!attenuated && this._previousVolume < 0)
            return;

        const easeInOutQuad = t => {
            return t < 0.5
                ? 2 * t * t
                : -1 + (4 - 2 * t) * t;
        };

        if (this._volumeRampTimeoutId)
            GLib.source_remove(this._volumeRampTimeoutId);
        this._volumeRampTimeoutId = null;

        if (attenuated) {
            const maxVolume = this._control.get_vol_max_norm();
            const fadeOutTargetVolume = Math.floor(caVolume * maxVolume / 100);
            const currentVolume = this._sink.volume;

            if (currentVolume <= fadeOutTargetVolume)
                return;

            this._previousVolume = currentVolume;
            const duration = 1000;
            const steps = 50;
            const interval = duration / steps;
            let step = 0;

            this._unmonitorSinkVolume();

            this._volumeRampTimeoutId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, interval, () => {
                if (step >= steps) {
                    this._sink.set_volume(fadeOutTargetVolume);
                    this._sink.push_volume();
                    this._monitorSinkVolume();
                    this._volumeRampTimeoutId = null;
                    return GLib.SOURCE_REMOVE;
                }

                const t = step / steps;
                const eased = easeInOutQuad(t);
                const newVolume =
                    Math.round(currentVolume + (fadeOutTargetVolume - currentVolume) * eased);

                this._sink.set_volume(newVolume);
                this._sink.push_volume();

                step++;
                return GLib.SOURCE_CONTINUE;
            });
        } else {
            const currentVolume = this._sink.volume;
            const fadeInTargetVolume = this._previousVolume;
            const duration = 1000;
            const steps = 50;
            const interval = duration / steps;
            let step = 0;

            this._unmonitorSinkVolume();

            this._volumeRampTimeoutId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, interval, () => {
                if (step >= steps) {
                    this._sink.set_volume(fadeInTargetVolume);
                    this._sink.push_volume();
                    this._previousVolume = -1;
                    this._monitorSinkVolume();
                    this._volumeRampTimeoutId = null;
                    return GLib.SOURCE_REMOVE;
                }

                const t = step / steps;
                const eased = easeInOutQuad(t);
                const newVolume =
                    Math.round(currentVolume + (fadeInTargetVolume - currentVolume) * eased);
                this._sink.set_volume(newVolume);
                this._sink.push_volume();

                step++;
                return GLib.SOURCE_CONTINUE;
            });
        }
    }

    _playerPropsChanged() {
        if (this._playbackStatusChangePending) {
            this._playbackStatusChangePending = false;
            return;
        }
        const status = this._playerProxy?.get_cached_property('PlaybackStatus')?.unpack();
        if (status !== 'Paused')
            this._lastPausedPlayer = null;
    }

    async _changeStatus() {
        if (this._playerProxy) {
            if (this._requestedState === 'pause') {
                try {
                    await this._playerProxy.call(
                        'Pause',
                        null,
                        Gio.DBusCallFlags.NONE,
                        -1,
                        null
                    );
                } catch (e) {
                    this._log.error(`Error call Mpris Pause method. Error: ${e}`);
                }
                const status = this._playerProxy?.get_cached_property('PlaybackStatus')?.unpack();
                this._playbackStatusChangePending = status !== 'Paused';
                this._playerProxyId = this._playerProxy.connect(
                    'g-properties-changed', () => this._playerPropsChanged());
            } else {
                try {
                    await this._playerProxy.call(
                        'Play',
                        null,
                        Gio.DBusCallFlags.NONE,
                        -1,
                        null
                    );
                } catch (e) {
                    this._log.error(`Error call Mpris Play method. Error: ${e}`);
                }
            }
        }
    }

    _onPlayerProxyReady() {
        const status = this._playerProxy?.get_cached_property('PlaybackStatus')?.unpack();
        if (this._requestedState === 'play' && status === 'Playing') {
            this._lastPausedPlayer = null;
            this._mprisNames = [];
        } else if (this._requestedState === 'play' && status === 'Paused') {
            this._lastPausedPlayer = null;
            this._mprisNames = [];
            this._changeStatus();
        } else if (this._requestedState === 'pause' && status === 'Playing') {
            this._mprisNames = [];
            this._lastPausedPlayer = this._busname;
            this._changeStatus();
        } else {
            this._playerProxy = null;
            this._iteratePlayers();
        }
    }

    async _initPlayerProxy(busname) {
        try {
            this._playerProxy = await Gio.DBusProxy.new_for_bus(
                Gio.BusType.SESSION,
                Gio.DBusProxyFlags.NONE,
                null,
                busname,
                '/org/mpris/MediaPlayer2',
                'org.mpris.MediaPlayer2.Player',
                null
            );
        } catch (e) {
            this._log.error(`Failed to initialize proxy in player proxy. Error: ${e}`);
            return;
        }
        this._onPlayerProxyReady();
    }

    _iteratePlayers() {
        if (this._mprisNames.length === 0)
            return;

        this._busname = this._mprisNames.shift();
        this._initPlayerProxy(this._busname);
    }

    _disconnectPlayerProxy() {
        if (this._playerProxyId)
            this._playerProxy?.disconnect(this._playerProxyId);
        this._playerProxy = null;
        this._playerProxyId = null;
    }

    async changeActivePlayerState(requestedState) {
        if (!this._controllerReady || !this._sink)
            return;

        if (requestedState === 'pause' && !this._sinkStateIsRunning)
            return;

        this._requestedState = requestedState;
        this._disconnectPlayerProxy();

        let names = [];
        try {
            const res = await Gio.DBus.session.call(
                'org.freedesktop.DBus',
                '/org/freedesktop/DBus',
                'org.freedesktop.DBus',
                'ListNames',
                null,
                new GLib.VariantType('(as)'),
                Gio.DBusCallFlags.NONE,
                -1,
                null
            );

            if (res)
                [names] = res.deepUnpack();
        } catch (e) {
            this._log.error(`Bluetooth-Battery-Meter: Error calling ListNames. Error: ${e}`);
            return;
        }

        this._mprisNames = names.filter(name => name.startsWith(MEDIA_PLAYER_PREFIX));
        if (this._requestedState === 'play') {
            if (this._lastPausedPlayer && this._mprisNames.includes(this._lastPausedPlayer))
                this._initPlayerProxy(this._lastPausedPlayer);
        } else {
            this._iteratePlayers();
        }
    }

    _onDestroy() {
        if (this._previousVolume > -1) {
            const lastAttenuationInfo = {
                path: this._devicePath,
                timestamp: Date.now(),
                volume: this._previousVolume,
            };
            this._settings.set_strv('attenuated-on-destroy-info',
                [JSON.stringify(lastAttenuationInfo)]);
        }
    }

    destroy() {
        if (this._volumeRampTimeoutId)
            GLib.source_remove(this._volumeRampTimeoutId);
        this._volumeRampTimeoutId = null;
        this._onDestroy();
        this._disconnectController();
        this._disconnectPlayerProxy();
        if (this._stateChangeId)
            this._control?.disconnect(this._stateChangeId);
        this._stateChangeId = null;
        this._controllerReady = false;
        this._lastPausedPlayer = null;
        this._playbackStatusChangePending = null;
        this._control = null;
    }
});


#include <algorithm>
#include <pipewire/pipewire.h>
#include <spa/param/audio/format-utils.h>
#include <spa/param/props.h>
#include <aubio/aubio.h>
#include <memory>
#include <iostream>
#include <fstream>
#include <csignal>
#include <atomic>
#include <vector>
#include <cstring>
#include <chrono>
#include <iomanip>
#include <sstream>
#include <thread>
#include <cmath>

class BeatDetector {
private:
    static constexpr uint32_t SAMPLE_RATE = 44100;
    static constexpr uint32_t CHANNELS = 1;
    
    pw_main_loop* main_loop_;
    pw_context* context_;
    pw_core* core_;
    pw_stream* stream_;
    
    std::unique_ptr<aubio_tempo_t, decltype(&del_aubio_tempo)> tempo_;
    std::unique_ptr<fvec_t, decltype(&del_fvec)> input_buffer_;
    std::unique_ptr<fvec_t, decltype(&del_fvec)> output_buffer_;
    std::unique_ptr<aubio_onset_t, decltype(&del_aubio_onset)> onset_;
    std::unique_ptr<aubio_pitch_t, decltype(&del_aubio_pitch)> pitch_;
    std::unique_ptr<fvec_t, decltype(&del_fvec)> pitch_buffer_;
    
    const uint32_t buf_size_;
    const uint32_t fft_size_;
    
    static std::atomic<bool> should_quit_;
    static BeatDetector* instance_;
    
    std::ofstream log_file_;
    bool enable_logging_;
    bool enable_performance_stats_;
    bool enable_pitch_detection_;
    
    std::vector<double> process_times_;
    uint64_t total_beats_;
    uint64_t total_onsets_;
    std::chrono::steady_clock::time_point start_time_;
    
    std::vector<float> recent_bpms_;
    static constexpr size_t BPM_HISTORY_SIZE = 10;
    float last_bpm_;

public:
    explicit BeatDetector(uint32_t buf_size = 512, 
                         bool enable_logging = false,
                         bool enable_performance_stats = false,
                         bool enable_pitch_detection = false) 
        : main_loop_(nullptr)
        , context_(nullptr)
        , core_(nullptr)
        , stream_(nullptr)
        , tempo_(nullptr, &del_aubio_tempo)
        , input_buffer_(nullptr, &del_fvec)
        , output_buffer_(nullptr, &del_fvec)
        , onset_(nullptr, &del_aubio_onset)
        , pitch_(nullptr, &del_aubio_pitch)
        , pitch_buffer_(nullptr, &del_fvec)
        , buf_size_(buf_size)
        , fft_size_(buf_size * 2)
        , enable_logging_(enable_logging)
        , enable_performance_stats_(enable_performance_stats)
        , enable_pitch_detection_(enable_pitch_detection)
        , total_beats_(0)
        , total_onsets_(0)
        , last_bpm_(0.0f)
    {
        instance_ = this;
        recent_bpms_.reserve(BPM_HISTORY_SIZE);
        if (enable_performance_stats_) {
            process_times_.reserve(1000);
        }
        initialize();
    }
    
    ~BeatDetector() {
        if (enable_performance_stats_) print_stats();
        cleanup();
        instance_ = nullptr;
    }
    
    BeatDetector(const BeatDetector&) = delete;
    BeatDetector& operator=(const BeatDetector&) = delete;
    
    bool initialize() {
        start_time_ = std::chrono::steady_clock::now();
        
        if (enable_logging_) {
            auto now = std::chrono::system_clock::now();
            auto time_t = std::chrono::system_clock::to_time_t(now);
            std::stringstream filename;
            filename << "beat_log_" << std::put_time(std::localtime(&time_t), "%Y%m%d_%H%M%S") << ".txt";
            log_file_.open(filename.str());
            if (log_file_.is_open()) {
                log_file_ << "# Timestamp,BPM,Onset,Pitch(Hz),ProcessTime(ms)\n";
            }
        }
        
        pw_init(nullptr, nullptr);
        
        main_loop_ = pw_main_loop_new(nullptr);
        if (!main_loop_) return false;
        
        context_ = pw_context_new(pw_main_loop_get_loop(main_loop_), nullptr, 0);
        if (!context_) return false;
        
        core_ = pw_context_connect(context_, nullptr, 0);
        if (!core_) return false;
        
        tempo_.reset(new_aubio_tempo("default", fft_size_, buf_size_, SAMPLE_RATE));
        if (!tempo_) return false;
        
        input_buffer_.reset(new_fvec(buf_size_));
        output_buffer_.reset(new_fvec(1));
        if (!input_buffer_ || !output_buffer_) return false;
        
        onset_.reset(new_aubio_onset("default", fft_size_, buf_size_, SAMPLE_RATE));
        if (!onset_) return false;
        
        if (enable_pitch_detection_) {
            pitch_.reset(new_aubio_pitch("default", fft_size_, buf_size_, SAMPLE_RATE));
            pitch_buffer_.reset(new_fvec(1));
            if (!pitch_ || !pitch_buffer_) return false;
            aubio_pitch_set_unit(pitch_.get(), "Hz");
        }
        
        return setup_stream();
    }
    
    void run() {
        if (!main_loop_) return;
        pw_main_loop_run(main_loop_);
    }
    
    void stop() {
        should_quit_ = true;
        if (main_loop_) {
            pw_main_loop_quit(main_loop_);
        }
    }
    
    static void signal_handler(int) {
        if (instance_) {
            instance_->stop();
        }
    }

private:
    void print_stats() {
        auto end_time = std::chrono::steady_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::seconds>(end_time - start_time_);
        
        std::cout << "Runtime: " << duration.count() << "s, "
                  << "Beats: " << total_beats_ << ", "
                  << "Onsets: " << total_onsets_;
        
        if (!process_times_.empty()) {
            double avg_time = 0;
            for (double t : process_times_) avg_time += t;
            avg_time /= process_times_.size();
            std::cout << ", Avg process time: " << std::fixed << std::setprecision(2) << avg_time << "ms";
        }
        
        if (!recent_bpms_.empty()) {
            float sum = 0;
            for (float bpm : recent_bpms_) sum += bpm;
            std::cout << ", Avg BPM: " << std::fixed << std::setprecision(1) << (sum / recent_bpms_.size());
        }
        std::cout << std::endl;
    }
    
    bool setup_stream() {
        static const pw_stream_events stream_events = {
            .version = PW_VERSION_STREAM_EVENTS,
            .destroy = nullptr,
            .state_changed = on_state_changed,
            .control_info = nullptr,
            .io_changed = nullptr,
            .param_changed = nullptr,
            .add_buffer = nullptr,
            .remove_buffer = nullptr,
            .process = on_process,
            .drained = nullptr,
            .command = nullptr,
            .trigger_done = nullptr,
        };
        
        // Non-intrusive properties for better compatibility
        pw_properties* props = pw_properties_new(
            PW_KEY_MEDIA_TYPE, "Audio",
            PW_KEY_MEDIA_CATEGORY, "Capture",
            PW_KEY_MEDIA_ROLE, "DSP",
            PW_KEY_APP_NAME, "beat-detector",
            PW_KEY_NODE_NAME, "beat-detector",
            PW_KEY_NODE_DESCRIPTION, "Audio Beat Detector",
            PW_KEY_STREAM_CAPTURE_SINK, "false",
            nullptr
        );
        
        stream_ = pw_stream_new_simple(
            pw_main_loop_get_loop(main_loop_),
            "beat-detector",
            props,
            &stream_events,
            this
        );
        
        if (!stream_) return false;
        
        uint8_t buffer[1024];
        spa_pod_builder pod_builder = SPA_POD_BUILDER_INIT(buffer, sizeof(buffer));
        
        struct spa_audio_info_raw audio_info = {};
        audio_info.format = SPA_AUDIO_FORMAT_F32_LE;
        audio_info.channels = CHANNELS;
        audio_info.rate = SAMPLE_RATE;
        
        const spa_pod* params[1];
        params[0] = spa_format_audio_raw_build(&pod_builder, SPA_PARAM_EnumFormat, &audio_info);
        
        // Use standard connection flags for better compatibility
        pw_stream_flags flags = static_cast<pw_stream_flags>(
            PW_STREAM_FLAG_AUTOCONNECT |
            PW_STREAM_FLAG_MAP_BUFFERS
        );
        
        return pw_stream_connect(stream_, PW_DIRECTION_INPUT, PW_ID_ANY, flags, params, 1) >= 0;
    }
    
    static void on_state_changed(void* userdata, enum pw_stream_state /* old_state */, 
                                enum pw_stream_state state, const char* /* error */) {
        auto* detector = static_cast<BeatDetector*>(userdata);
        
        if (state == PW_STREAM_STATE_ERROR) {
            detector->stop();
        }
    }
    
    static void on_process(void* userdata) {
        auto* detector = static_cast<BeatDetector*>(userdata);
        detector->process_audio();
    }
    
    void process_audio() {
        if (should_quit_) return;
        
        auto process_start = std::chrono::high_resolution_clock::now();
        
        pw_buffer* buffer = pw_stream_dequeue_buffer(stream_);
        if (!buffer) return;
        
        spa_buffer* spa_buf = buffer->buffer;
        if (!spa_buf->datas[0].data) {
            pw_stream_queue_buffer(stream_, buffer);
            return;
        }
        
        const float* audio_data = static_cast<const float*>(spa_buf->datas[0].data);
        const uint32_t n_samples = spa_buf->datas[0].chunk->size / sizeof(float);
        
        for (uint32_t offset = 0; offset + buf_size_ <= n_samples; offset += buf_size_) {
            std::memcpy(input_buffer_->data, audio_data + offset, buf_size_ * sizeof(float));
            
            aubio_tempo_do(tempo_.get(), input_buffer_.get(), output_buffer_.get());
            bool is_beat = output_buffer_->data[0] != 0.0f;
            
            aubio_onset_do(onset_.get(), input_buffer_.get(), output_buffer_.get());
            bool is_onset = output_buffer_->data[0] != 0.0f;
            
            float pitch_hz = 0.0f;
            if (enable_pitch_detection_) {
                aubio_pitch_do(pitch_.get(), input_buffer_.get(), pitch_buffer_.get());
                pitch_hz = pitch_buffer_->data[0];
            }
            
            if (is_beat) {
                total_beats_++;
                last_bpm_ = aubio_tempo_get_bpm(tempo_.get());
                
                recent_bpms_.push_back(last_bpm_);
                if (recent_bpms_.size() > BPM_HISTORY_SIZE) {
                    recent_bpms_.erase(recent_bpms_.begin());
                }
                
                std::cout << "Beat: " << std::fixed << std::setprecision(1) << last_bpm_ << " BPM" << std::endl;
            }
            
            if (is_onset) {
                total_onsets_++;
            }
            
            if (enable_logging_ && log_file_.is_open() && (is_beat || is_onset)) {
                auto now = std::chrono::system_clock::now();
                auto time_t = std::chrono::system_clock::to_time_t(now);
                auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                    now.time_since_epoch()) % 1000;
                
                log_file_ << std::put_time(std::localtime(&time_t), "%H:%M:%S") 
                         << "." << std::setfill('0') << std::setw(3) << ms.count() << ","
                         << (is_beat ? last_bpm_ : 0) << ","
                         << (is_onset ? 1 : 0) << ","
                         << pitch_hz << ",";
            }
        }
        
        pw_stream_queue_buffer(stream_, buffer);
        
        if (enable_performance_stats_) {
            auto process_end = std::chrono::high_resolution_clock::now();
            auto process_time = std::chrono::duration<double, std::milli>(process_end - process_start).count();
            
            if (log_file_.is_open() && (total_beats_ > 0 || total_onsets_ > 0)) {
                log_file_ << std::fixed << std::setprecision(3) << process_time << "\n";
            }
            
            if (process_times_.size() < 1000) {
                process_times_.push_back(process_time);
            }
        }
    }
    
    void cleanup() {
        if (log_file_.is_open()) {
            log_file_.close();
        }
        
        if (stream_) {
            pw_stream_destroy(stream_);
            stream_ = nullptr;
        }
        
        if (core_) {
            pw_core_disconnect(core_);
            core_ = nullptr;
        }
        
        if (context_) {
            pw_context_destroy(context_);
            context_ = nullptr;
        }
        
        if (main_loop_) {
            pw_main_loop_destroy(main_loop_);
            main_loop_ = nullptr;
        }
        
        tempo_.reset();
        input_buffer_.reset();
        output_buffer_.reset();
        onset_.reset();
        pitch_.reset();
        pitch_buffer_.reset();
        
        pw_deinit();
    }
};

std::atomic<bool> BeatDetector::should_quit_{false};
BeatDetector* BeatDetector::instance_{nullptr};

void print_usage() {
    std::cout << "Usage: ./beat_detector [buffer_size] [--log] [--stats] [--pitch]\n";
    std::cout << "  buffer_size: 64-8192 (default: 512)\n";
    std::cout << "  --log:       Enable logging\n";
    std::cout << "  --stats:     Enable performance statistics\n";
    std::cout << "  --pitch:     Enable pitch detection\n";
}

int main(int argc, char* argv[]) {
    uint32_t buffer_size = 512;
    bool enable_logging = false;
    bool enable_performance_stats = false;
    bool enable_pitch_detection = false;
    
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        
        if (arg == "--help" || arg == "-h") {
            print_usage();
            return 0;
        } else if (arg == "--log") {
            enable_logging = true;
        } else if (arg == "--stats") {
            enable_performance_stats = true;
        } else if (arg == "--pitch") {
            enable_pitch_detection = true;
        } else if (arg[0] != '-') {
            try {
                buffer_size = std::stoul(arg);
                if (buffer_size < 64 || buffer_size > 8192) {
                    std::cerr << "Buffer size must be between 64 and 8192" << std::endl;
                    return 1;
                }
            } catch (...) {
                std::cerr << "Invalid buffer size: " << arg << std::endl;
                return 1;
            }
        } else {
            std::cerr << "Unknown option: " << arg << std::endl;
            print_usage();
            return 1;
        }
    }
    
    std::signal(SIGINT, BeatDetector::signal_handler);
    std::signal(SIGTERM, BeatDetector::signal_handler);
    
    try {
        BeatDetector detector(buffer_size, enable_logging, enable_performance_stats, enable_pitch_detection);
        detector.run();
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}

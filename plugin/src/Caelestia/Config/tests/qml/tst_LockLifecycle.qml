pragma ComponentBehavior: Bound

import QtQuick
import QtTest
import "../../../../../../modules/lock" as Lock

// qmllint disable unqualified
TestCase {
    name: "LockLifecycle"

    function createLifecycle(properties): var {
        return lifecycleComponent.createObject(this, properties);
    }

    function createSpy(lifecycle, signalName): var {
        return signalSpyComponent.createObject(lifecycle, {
            target: lifecycle,
            signalName: signalName
        });
    }

    function ignoreLifecycleWarning(message): void {
        ignoreWarning(new RegExp(message));
    }

    function test_secureAndReleaseFireOncePerCycle(): void {
        const lifecycle = createLifecycle({
            secureCommand: ["hook", "secure"],
            releaseCommand: ["hook", "release"]
        });
        const secureSpy = createSpy(lifecycle, "secureHookRequested");
        const releaseSpy = createSpy(lifecycle, "releaseHookRequested");

        verify(lifecycle.initialize(false, false));
        lifecycle.update(true, false);
        lifecycle.update(true, true);
        lifecycle.update(true, true);
        compare(secureSpy.count, 1);
        compare(secureSpy.signalArguments[0][0], ["hook", "secure"]);
        compare(releaseSpy.count, 0);

        lifecycle.update(true, false);
        compare(releaseSpy.count, 0);
        lifecycle.update(false, false);
        lifecycle.update(false, false);
        compare(releaseSpy.count, 1);
        compare(releaseSpy.signalArguments[0][0], ["hook", "release"]);

        lifecycle.update(true, false);
        lifecycle.update(false, false);
        compare(secureSpy.count, 1);
        compare(releaseSpy.count, 2);
    }

    function test_preservesSecuredCycleAcrossReload(): void {
        const first = createLifecycle({
            secureCommand: ["hook", "secure"]
        });
        const firstSecureSpy = createSpy(first, "secureHookRequested");

        verify(first.initialize(false, false));
        first.update(true, true);
        compare(firstSecureSpy.count, 1);

        const restored = createLifecycle({
            secureCommand: ["hook", "secure"],
            releaseCommand: ["hook", "release"]
        });
        const secureSpy = createSpy(restored, "secureHookRequested");
        const releaseSpy = createSpy(restored, "releaseHookRequested");

        verify(restored.initialize(true, true));
        restored.update(true, true);
        compare(secureSpy.count, 0);
        restored.update(false, false);
        restored.update(false, false);
        compare(releaseSpy.count, 1);
    }

    function test_initializationSnapshots(): void {
        const idle = createLifecycle({
            secureCommand: ["hook", "secure"],
            releaseCommand: ["hook", "release"]
        });
        const idleSecureSpy = createSpy(idle, "secureHookRequested");
        const idleReleaseSpy = createSpy(idle, "releaseHookRequested");
        verify(idle.initialize(false, false));
        idle.update(false, false);
        compare(idleSecureSpy.count, 0);
        compare(idleReleaseSpy.count, 0);

        const inconsistent = createLifecycle({
            secureCommand: ["hook", "secure"],
            releaseCommand: ["hook", "release"]
        });
        const inconsistentSecureSpy = createSpy(inconsistent, "secureHookRequested");
        const inconsistentReleaseSpy = createSpy(inconsistent, "releaseHookRequested");
        verify(inconsistent.initialize(false, true));
        inconsistent.update(false, true);
        compare(inconsistentSecureSpy.count, 0);
        compare(inconsistentReleaseSpy.count, 0);

        const preSecure = createLifecycle({
            secureCommand: ["hook", "secure"],
            releaseCommand: ["hook", "release"]
        });
        const preSecureSpy = createSpy(preSecure, "secureHookRequested");
        const preReleaseSpy = createSpy(preSecure, "releaseHookRequested");
        verify(preSecure.initialize(true, false));
        preSecure.update(true, true);
        preSecure.update(false, false);
        compare(preSecureSpy.count, 1);
        compare(preReleaseSpy.count, 1);

        const secured = createLifecycle({
            secureCommand: ["hook", "secure"],
            releaseCommand: ["hook", "release"]
        });
        const securedSecureSpy = createSpy(secured, "secureHookRequested");
        const securedReleaseSpy = createSpy(secured, "releaseHookRequested");
        verify(secured.initialize(true, true));
        secured.update(true, true);
        secured.update(false, false);
        compare(securedSecureSpy.count, 0);
        compare(securedReleaseSpy.count, 1);
    }

    function test_rejectsInitializationMisuse(): void {
        const lifecycle = createLifecycle({
            secureCommand: ["hook", "secure"],
            releaseCommand: ["hook", "release"]
        });
        const secureSpy = createSpy(lifecycle, "secureHookRequested");
        const releaseSpy = createSpy(lifecycle, "releaseHookRequested");

        ignoreLifecycleWarning("Lock lifecycle update before initialization");
        lifecycle.update(true, true);
        compare(secureSpy.count, 0);
        compare(releaseSpy.count, 0);

        verify(lifecycle.initialize(false, false));
        ignoreLifecycleWarning("Lock lifecycle controller initialized more than once");
        verify(!lifecycle.initialize(true, true));
        lifecycle.update(false, false);
        compare(secureSpy.count, 0);
        compare(releaseSpy.count, 0);
    }

    function test_suppressesBlankExecutables(): void {
        const lifecycle = createLifecycle({
            secureCommand: ["   ", "secure"],
            releaseCommand: [""]
        });
        const secureSpy = createSpy(lifecycle, "secureHookRequested");
        const releaseSpy = createSpy(lifecycle, "releaseHookRequested");

        verify(lifecycle.initialize(false, false));
        ignoreLifecycleWarning("Ignoring lock lifecycle hook with blank argv\\[0\\]");
        lifecycle.update(true, true);
        ignoreLifecycleWarning("Ignoring lock lifecycle hook with blank argv\\[0\\]");
        lifecycle.update(false, false);
        compare(secureSpy.count, 0);
        compare(releaseSpy.count, 0);
    }

    Component {
        id: lifecycleComponent

        Lock.LockLifecycle {}
    }

    Component {
        id: signalSpyComponent

        SignalSpy {}
    }
}

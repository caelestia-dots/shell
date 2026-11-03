import "../services/HyprsunsetVersion.js" as HyprsunsetVersion
import QtQuick
import QtTest

Item {
    width: 1
    height: 1

    TestCase {
        function test_oldVersionCannotBeProbed() {
            verify(!HyprsunsetVersion.supportsIdentityQuery("hyprsunset v0.3.3"));
            verify(!HyprsunsetVersion.supportsIdentityQuery("hyprsunset v0.2.1"));
            verify(!HyprsunsetVersion.supportsIdentityQuery("hyprsunset v0.3.10"));
        }

        function test_supportedVersions() {
            verify(HyprsunsetVersion.supportsIdentityQuery("hyprsunset v0.4.0"));
            verify(HyprsunsetVersion.supportsIdentityQuery("hyprsunset v0.4.12"));
            verify(HyprsunsetVersion.supportsIdentityQuery("hyprsunset v0.10.1"));
            verify(HyprsunsetVersion.supportsIdentityQuery("hyprsunset v1.0.0"));
        }

        function test_unrecognizedVersionIsUnavailable() {
            verify(!HyprsunsetVersion.supportsIdentityQuery(""));
            verify(!HyprsunsetVersion.supportsIdentityQuery("hyprsunset version unknown"));
            verify(!HyprsunsetVersion.supportsIdentityQuery("hyprsunset v0.4-alpha"));
            verify(!HyprsunsetVersion.supportsIdentityQuery("hyprctl v0.4.0"));
        }

        name: "HyprsunsetCompatibility"
        when: windowShown
    }
}

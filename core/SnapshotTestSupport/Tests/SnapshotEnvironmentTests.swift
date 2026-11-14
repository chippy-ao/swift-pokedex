import Testing

@testable import SnapshotTestSupport

/// 撮る環境の確認。違う環境で撮ると、描画の差で画像がずれる。そのとき、原因が分かる失敗にする。
@MainActor
struct SnapshotEnvironmentTests {
    @Test func returnsNilWhenDeviceAndOSMatch() {
        let message = SnapshotEnvironment.mismatchMessage(
            deviceName: SnapshotEnvironment.simulatorName,
            osVersion: SnapshotEnvironment.osVersion)
        #expect(message == nil)
    }

    @Test func returnsMessageWhenDeviceNameDiffers() throws {
        let message = try #require(
            SnapshotEnvironment.mismatchMessage(
                deviceName: "iPhone 17 Pro", osVersion: SnapshotEnvironment.osVersion))
        // 今の機種名と、求める機種名の両方が、メッセージから分かる
        #expect(message.contains("iPhone 17 Pro"))
        #expect(message.contains(SnapshotEnvironment.simulatorName))
    }

    @Test func returnsMessageWhenOSVersionDiffers() throws {
        let message = try #require(
            SnapshotEnvironment.mismatchMessage(
                deviceName: SnapshotEnvironment.simulatorName, osVersion: "26.0"))
        #expect(message.contains("26.0"))
        #expect(message.contains(SnapshotEnvironment.osVersion))
    }

    @Test func returnsMessageOutsideSimulator() throws {
        // シミュレーター以外では、環境変数が無く、機種名が nil になる
        let message = try #require(
            SnapshotEnvironment.mismatchMessage(
                deviceName: nil, osVersion: SnapshotEnvironment.osVersion))
        #expect(message.contains("シミュレーター以外"))
    }
}

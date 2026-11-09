import ManagedSettings
import ManagedSettingsUI
import UIKit

// Keep the class name Xcode generated.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private func listenShield() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor.black.withAlphaComponent(0.85),
            icon: UIImage(systemName: "headphones")?.withTintColor(.white, renderingMode: .alwaysOriginal),
            title: ShieldConfiguration.Label(text: "Time's up", color: .white),
            subtitle: ShieldConfiguration.Label(text: "Listen to something calm to earn minutes back.", color: .lightGray),
            primaryButtonLabel: ShieldConfiguration.Label(text: "Listen", color: .black),
            primaryButtonBackgroundColor: .white,
            secondaryButtonLabel: ShieldConfiguration.Label(text: "Close", color: .white)
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        listenShield()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        listenShield()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        listenShield()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        listenShield()
    }
}

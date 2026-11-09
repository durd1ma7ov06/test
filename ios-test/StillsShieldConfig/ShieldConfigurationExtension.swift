import ManagedSettings
import ManagedSettingsUI
import UIKit

/// ShieldConfigurationExtension
/// Bloklangan ilova ochilganda iOS tomonidan ko'rsatiladigan ekranni chizuvchi komponent.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private func createShieldConfiguration() -> ShieldConfiguration {
        // Yuqori kontrastli, zamonaviy qora shaffof (Ultra Thin Dark Material) uslubi
        let iconImage = UIImage(systemName: "headphones")?.withTintColor(.white, renderingMode: .alwaysOriginal)

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: UIColor.black.withAlphaComponent(0.88),
            icon: iconImage,
            title: ShieldConfiguration.Label(
                text: "Vaqt tugadi ⏳",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "Diqqatingizni jamlash vaqti keldi. Qayta vaqt olish uchun qisqa audio eshiting.",
                color: UIColor(white: 0.85, alpha: 1.0)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Eshitish (Listen) 🎧",
                color: .black
            ),
            primaryButtonBackgroundColor: .white,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "Yopish (Close)",
                color: UIColor(white: 0.7, alpha: 1.0)
            )
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        createShieldConfiguration()
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        createShieldConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        createShieldConfiguration()
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        createShieldConfiguration()
    }
}

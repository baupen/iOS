// Generated using SwiftGen, by O.Halligon — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// swiftlint:disable explicit_type_interface identifier_name line_length nesting type_body_length type_name
internal enum L10n {

  internal enum Alert {
    /// Abbrechen
    internal static let cancel = L10n.tr("Localizable", "alert.cancel")
    /// Okay
    internal static let okay = L10n.tr("Localizable", "alert.okay")

    internal enum ConnectionIssues {
      /// Es konnte keine Verbindung zum Dienst aufgebaut werden.
      internal static let message = L10n.tr("Localizable", "alert.connection_issues.message")
      /// Verbindungsproblem
      internal static let title = L10n.tr("Localizable", "alert.connection_issues.title")
    }

    internal enum UnknownSyncError {
      /// Beim aktualisieren ist ein unbekannter Fehler aufgetreten. Bitte versuch es später nochmal.
      internal static let message = L10n.tr("Localizable", "alert.unknown_sync_error.message")
      /// Unbekannter Fehler!
      internal static let title = L10n.tr("Localizable", "alert.unknown_sync_error.title")
    }
  }

  internal enum BuildingList {
    /// Ausloggen
    internal static let logOut = L10n.tr("Localizable", "building_list.log_out")
    /// Gebäude
    internal static let title = L10n.tr("Localizable", "building_list.title")
    /// Willkommen, %@
    internal static func welcome(_ p1: String) -> String {
      return L10n.tr("Localizable", "building_list.welcome", p1)
    }

    internal enum BuildingSummary {
      /// %@ offene Pendenzen
      internal static func openIssues(_ p1: String) -> String {
        return L10n.tr("Localizable", "building_list.building_summary.open_issues", p1)
      }
      /// %@ insgesamt
      internal static func totalIssues(_ p1: String) -> String {
        return L10n.tr("Localizable", "building_list.building_summary.total_issues", p1)
      }
    }

    internal enum ClientMode {
      /// Im Abnahmemodus werden nur die Pendenzen angezeigt, die auch im Abnahmemodus erfasst wurden.\nIm Abnahmemodus erfasste Pendenzen werden hingegen auch sonst angezeigt.
      internal static let description = L10n.tr("Localizable", "building_list.client_mode.description")
      /// Abnahmemodus
      internal static let title = L10n.tr("Localizable", "building_list.client_mode.title")
    }
  }

  internal enum Login {

    internal enum Alert {

      internal enum LoginError {
        /// Beim einloggen ist ein Fehler aufgetreten! Du wirst falls möglich lokal eingeloggt.
        internal static let message = L10n.tr("Localizable", "login.alert.login_error.message")
        /// Unbekannter Fehler!
        internal static let title = L10n.tr("Localizable", "login.alert.login_error.title")
      }

      internal enum WrongPassword {
        /// Das ist nicht das richtige Passwort für den Benutzer %@.
        internal static func message(_ p1: String) -> String {
          return L10n.tr("Localizable", "login.alert.wrong_password.message", p1)
        }
        /// Falsches Passwort!
        internal static let title = L10n.tr("Localizable", "login.alert.wrong_password.title")
      }

      internal enum WrongUsername {
        /// Es gibt keinen Benutzer namens %@.
        internal static func message(_ p1: String) -> String {
          return L10n.tr("Localizable", "login.alert.wrong_username.message", p1)
        }
        /// Falscher Benutzername!
        internal static let title = L10n.tr("Localizable", "login.alert.wrong_username.title")
      }
    }

    internal enum Placeholder {
      /// Passwort
      internal static let password = L10n.tr("Localizable", "login.placeholder.password")
      /// Benutzername
      internal static let username = L10n.tr("Localizable", "login.placeholder.username")
    }
  }
}
// swiftlint:enable explicit_type_interface identifier_name line_length nesting type_body_length type_name

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleToken.self), comment: "")
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {}

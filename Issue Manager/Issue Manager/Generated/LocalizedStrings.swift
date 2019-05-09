// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name
internal enum L10n {

  internal enum Alert {
    /// Abbrechen
    internal static let cancel = L10n.tr("Localizable", "alert.cancel")
    /// OK
    internal static let okay = L10n.tr("Localizable", "alert.okay")
    internal enum ConnectionIssues {
      /// Es konnte keine Verbindung zum Dienst aufgebaut werden.
      internal static let message = L10n.tr("Localizable", "alert.connection_issues.message")
      /// Verbindungsproblem
      internal static let title = L10n.tr("Localizable", "alert.connection_issues.title")
    }
    internal enum InvalidSession {
      /// Bitte loggen sie sich wieder neu ein.
      internal static let message = L10n.tr("Localizable", "alert.invalid_session.message")
      /// Ungültige Sitzung!
      internal static let title = L10n.tr("Localizable", "alert.invalid_session.title")
    }
    internal enum OutdatedClient {
      /// Diese Version der App kann nicht mehr mit dem Server kommunizieren. Bitte installier das neuste Update, um die App weiter zu benutzen.
      internal static let message = L10n.tr("Localizable", "alert.outdated_client.message")
      /// Update Erforderlich
      internal static let title = L10n.tr("Localizable", "alert.outdated_client.title")
    }
    internal enum UnknownSyncError {
      /// Beim Aktualisieren ist ein unbekannter Fehler aufgetreten. Bitte versuch es später nochmal.\n\nFalls der Fehler bestehen bleibt, könnte der folgende Text dem Support behilflich sein:\n%@
      internal static func message(_ p1: String) -> String {
        return L10n.tr("Localizable", "alert.unknown_sync_error.message", p1)
      }
      /// Unbekannter Fehler!
      internal static let title = L10n.tr("Localizable", "alert.unknown_sync_error.title")
    }
  }

  internal enum Issue {
    /// Handwerker
    internal static let craftsman = L10n.tr("Localizable", "issue.craftsman")
    /// Name
    internal static let craftsmanName = L10n.tr("Localizable", "issue.craftsman_name")
    /// Beschreibung
    internal static let description = L10n.tr("Localizable", "issue.description")
    /// Abnahmemodus
    internal static let isClientMode = L10n.tr("Localizable", "issue.is_client_mode")
    /// Kein Handwerker
    internal static let noCraftsman = L10n.tr("Localizable", "issue.no_craftsman")
    /// Keine Beschreibung
    internal static let noDescription = L10n.tr("Localizable", "issue.no_description")
    /// Status
    internal static let status = L10n.tr("Localizable", "issue.status")
    /// Funktion
    internal static let trade = L10n.tr("Localizable", "issue.trade")
    /// neu
    internal static let unregistered = L10n.tr("Localizable", "issue.unregistered")
    internal enum IsClientMode {
      /// Normal aufgenommen
      internal static let `false` = L10n.tr("Localizable", "issue.is_client_mode.false")
      /// Im Abnahmemodus aufgenommen
      internal static let `true` = L10n.tr("Localizable", "issue.is_client_mode.true")
    }
    internal enum Status {
      /// Neu
      internal static let new = L10n.tr("Localizable", "issue.status.new")
      /// Im Verzeichnis
      internal static let registered = L10n.tr("Localizable", "issue.status.registered")
      /// Registriert von %@
      internal static func registeredBy(_ p1: String) -> String {
        return L10n.tr("Localizable", "issue.status.registered_by", p1)
      }
      /// Beantwortet
      internal static let responded = L10n.tr("Localizable", "issue.status.responded")
      /// Beantwortet von %@
      internal static func respondedBy(_ p1: String) -> String {
        return L10n.tr("Localizable", "issue.status.responded_by", p1)
      }
      /// Abgeschlossen
      internal static let reviewed = L10n.tr("Localizable", "issue.status.reviewed")
      /// Bestätigt von %@
      internal static func reviewedBy(_ p1: String) -> String {
        return L10n.tr("Localizable", "issue.status.reviewed_by", p1)
      }
    }
  }

  internal enum Login {
    /// Eingeloggt Bleiben
    internal static let stayLoggedIn = L10n.tr("Localizable", "login.stay_logged_in")
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

  internal enum Map {
    /// Der Grundriss konnte nicht geladen werden!
    internal static let couldNotLoad = L10n.tr("Localizable", "map.could_not_load")
    /// Bereichweite Pendenz Erfassen
    internal static let newUnpositionedIssue = L10n.tr("Localizable", "map.new_unpositioned_issue")
    /// Wähle links einen Bereich aus, um hier den zugehörigen Grundriss zu sehen.
    internal static let noMapSelected = L10n.tr("Localizable", "map.no_map_selected")
    /// Der Bereich "%@" hat keinen zugehörigen Grundriss.
    internal static func noPdf(_ p1: String) -> String {
      return L10n.tr("Localizable", "map.no_pdf", p1)
    }
    /// Grundriss wird geladen…
    internal static let pdfLoading = L10n.tr("Localizable", "map.pdf_loading")
    /// Grundriss
    internal static let title = L10n.tr("Localizable", "map.title")
    internal enum IssueList {
      /// Details Anzeigen
      internal static let showDetails = L10n.tr("Localizable", "map.issue_list.show_details")
      /// Auf Grundriss Anzeigen
      internal static let showInMap = L10n.tr("Localizable", "map.issue_list.show_in_map")
      /// %@ Pendenzen offen; %@ insgesamt
      internal static func summary(_ p1: String, _ p2: String) -> String {
        return L10n.tr("Localizable", "map.issue_list.summary", p1, p2)
      }
      /// Filter aktiv: %@/%@ Pendenzen angezeigt
      internal static func summaryFiltered(_ p1: String, _ p2: String) -> String {
        return L10n.tr("Localizable", "map.issue_list.summary_filtered", p1, p2)
      }
    }
    internal enum StatusFilter {
      /// Es werden alle Pendenzen angezeigt.
      internal static let allSelected = L10n.tr("Localizable", "map.status_filter.all_selected")
      /// Es werden keine Pendenzen angezeigt.
      internal static let noneSelected = L10n.tr("Localizable", "map.status_filter.none_selected")
      /// Es werden nur Pendenzen mit einem der ausgewählten Status angezeigt.
      internal static let someSelected = L10n.tr("Localizable", "map.status_filter.some_selected")
      /// Filter nach Status
      internal static let title = L10n.tr("Localizable", "map.status_filter.title")
    }
  }

  internal enum MapList {
    internal enum MapRemoved {
      /// Dieser Bereich existiert nicht mehr. Du wirst jetzt zurück zur Baustellenauswahl geleitet.
      internal static let message = L10n.tr("Localizable", "map_list.map_removed.message")
      /// Bereich Entfernt!
      internal static let title = L10n.tr("Localizable", "map_list.map_removed.title")
    }
    internal enum MapSummary {
      /// %@ offene Pendenzen
      internal static func openIssues(_ p1: String) -> String {
        return L10n.tr("Localizable", "map_list.map_summary.open_issues", p1)
      }
    }
    internal enum Section {
      /// Untergeordnete Bereiche
      internal static let childMaps = L10n.tr("Localizable", "map_list.section.child_maps")
      /// Dieser Bereich
      internal static let thisMap = L10n.tr("Localizable", "map_list.section.this_map")
    }
  }

  internal enum Markup {
    /// Zeichnen
    internal static let title = L10n.tr("Localizable", "markup.title")
  }

  internal enum SiteList {
    /// Ausloggen
    internal static let logOut = L10n.tr("Localizable", "site_list.log_out")
    /// Noch keine Daten geladen!\nZieh runter, um die lokalen Daten mit dem Server zu synchronisieren.
    internal static let refreshHint = L10n.tr("Localizable", "site_list.refresh_hint")
    /// Baustellen
    internal static let title = L10n.tr("Localizable", "site_list.title")
    /// Willkommen, %@
    internal static func welcome(_ p1: String) -> String {
      return L10n.tr("Localizable", "site_list.welcome", p1)
    }
    internal enum ClientMode {
      /// Im Abnahmemodus werden nur die Pendenzen angezeigt, die auch im Abnahmemodus erfasst wurden.
      internal static let description = L10n.tr("Localizable", "site_list.client_mode.description")
      /// Abnahmemodus
      internal static let title = L10n.tr("Localizable", "site_list.client_mode.title")
    }
    internal enum SiteSummary {
      /// %@ offene Pendenzen
      internal static func openIssues(_ p1: String) -> String {
        return L10n.tr("Localizable", "site_list.site_summary.open_issues", p1)
      }
      /// %@ insgesamt
      internal static func totalIssues(_ p1: String) -> String {
        return L10n.tr("Localizable", "site_list.site_summary.total_issues", p1)
      }
    }
  }

  internal enum Trial {
    /// Zurück zum Login
    internal static let backToLogin = L10n.tr("Localizable", "trial.back_to_login")
    /// Probekonto Erstellen
    internal static let createAccount = L10n.tr("Localizable", "trial.create_account")
    /// Du hast ein Probekonto erstellt. Die Anmeldung erfolgt mit den folgenden Daten, die du auch auf www.app.mangel.io verwenden kannst.
    internal static let existingAccountHint = L10n.tr("Localizable", "trial.existing_account_hint")
    /// Einloggen
    internal static let logIn = L10n.tr("Localizable", "trial.log_in")
    internal enum Placeholder {
      /// Nachname
      internal static let familyName = L10n.tr("Localizable", "trial.placeholder.family_name")
      /// Vorname
      internal static let givenName = L10n.tr("Localizable", "trial.placeholder.given_name")
    }
  }

  internal enum ViewIssue {
    /// Annehmen
    internal static let acceptResponse = L10n.tr("Localizable", "view_issue.accept_response")
    /// Aktionen
    internal static let actions = L10n.tr("Localizable", "view_issue.actions")
    /// Tippe, um ein Foto zu machen.
    internal static let cameraControlHint = L10n.tr("Localizable", "view_issue.camera_control_hint")
    /// Die Kamera konnte nicht aktiviert werden!
    internal static let couldNotActivateCamera = L10n.tr("Localizable", "view_issue.could_not_activate_camera")
    /// Handwerker
    internal static let craftsman = L10n.tr("Localizable", "view_issue.craftsman")
    /// Beschreibung
    internal static let description = L10n.tr("Localizable", "view_issue.description")
    /// Details
    internal static let details = L10n.tr("Localizable", "view_issue.details")
    /// Foto
    internal static let image = L10n.tr("Localizable", "view_issue.image")
    /// Kein Foto gesetzt
    internal static let imagePlaceholder = L10n.tr("Localizable", "view_issue.image_placeholder")
    /// Im Abnahmemodus aufgenommen
    internal static let isClientMode = L10n.tr("Localizable", "view_issue.is_client_mode")
    /// Als Abgeschlossen Markieren
    internal static let markAsCompleted = L10n.tr("Localizable", "view_issue.mark_as_completed")
    /// Auf Foto Zeichnen
    internal static let markup = L10n.tr("Localizable", "view_issue.markup")
    /// Keine passenden Vorschläge
    internal static let noSuggestions = L10n.tr("Localizable", "view_issue.no_suggestions")
    /// Keine Funktion
    internal static let noTrade = L10n.tr("Localizable", "view_issue.no_trade")
    /// Ablehnen
    internal static let rejectResponse = L10n.tr("Localizable", "view_issue.reject_response")
    /// Erneut Versuchen
    internal static let retryCamera = L10n.tr("Localizable", "view_issue.retry_camera")
    /// Neue Pendenz
    internal static let titleCreating = L10n.tr("Localizable", "view_issue.title_creating")
    /// Pendenz Bearbeiten
    internal static let titleEditing = L10n.tr("Localizable", "view_issue.title_editing")
    /// Pendenzdetails
    internal static let titleViewing = L10n.tr("Localizable", "view_issue.title_viewing")
    /// Wieder Eröffnen
    internal static let undoReview = L10n.tr("Localizable", "view_issue.undo_review")
    internal enum CouldNotOpenLibrary {
      /// Um die Fotoauswahl zu öffnen, braucht diese App in den Einstellungen Zugriff auf deine Fotos.
      internal static let message = L10n.tr("Localizable", "view_issue.could_not_open_library.message")
      /// Fotoauswahl nicht möglich!
      internal static let title = L10n.tr("Localizable", "view_issue.could_not_open_library.title")
    }
    internal enum CouldNotSaveImage {
      /// Das Bild konnte nicht abgespeichert werden!
      internal static let title = L10n.tr("Localizable", "view_issue.could_not_save_image.title")
    }
    internal enum CouldNotTakePicture {
      /// Fotoaufnahme fehlgeschlagen!
      internal static let title = L10n.tr("Localizable", "view_issue.could_not_take_picture.title")
    }
    internal enum IsClientMode {
      /// Nein
      internal static let `false` = L10n.tr("Localizable", "view_issue.is_client_mode.false")
      /// Ja
      internal static let `true` = L10n.tr("Localizable", "view_issue.is_client_mode.true")
    }
    internal enum SelectCraftsman {
      /// Kein Handwerker
      internal static let `none` = L10n.tr("Localizable", "view_issue.select_craftsman.none")
      /// Handwerker
      internal static let title = L10n.tr("Localizable", "view_issue.select_craftsman.title")
    }
    internal enum SelectTrade {
      /// Keine Funktion
      internal static let `none` = L10n.tr("Localizable", "view_issue.select_trade.none")
      /// Funktionen
      internal static let title = L10n.tr("Localizable", "view_issue.select_trade.title")
    }
    internal enum Summary {
      /// Diese Pendenz wurde vom Handwerker beantwortet.\nDu kannst diese Antwort entweder bestätigen (um die Pendenz abzuschliessen) oder ablehnen (und sie somit rückgängig machen).
      internal static let hasResponse = L10n.tr("Localizable", "view_issue.summary.has_response")
      /// Diese Pendenz wurde noch nicht vom Handwerker beantwortet.\nDu kannst sie trotzdem bestätigen und somit als abgeschlossen markieren.
      internal static let noResponse = L10n.tr("Localizable", "view_issue.summary.no_response")
      /// Diese Pendenz wurde bereits abgeschlossen.\nDu kannst die Bestätigung rückgangig machen, um sie wieder zu eröffnen.
      internal static let reviewed = L10n.tr("Localizable", "view_issue.summary.reviewed")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    // swiftlint:disable:next nslocalizedstring_key
    let format = NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleToken.self), comment: "")
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {}

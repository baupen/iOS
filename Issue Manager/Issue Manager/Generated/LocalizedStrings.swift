// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:disable nesting type_body_length type_name vertical_whitespace_opening_braces
internal enum L10n {
  /// Schliessen
  internal static let closeSheet = L10n.tr("Localizable", "close_sheet", fallback: "Schliessen")
  internal enum Alert {
    /// Abbrechen
    internal static let cancel = L10n.tr("Localizable", "alert.cancel", fallback: "Abbrechen")
    /// Mehr Informationen…
    internal static let moreInfo = L10n.tr("Localizable", "alert.more_info", fallback: "Mehr Informationen…")
    /// OK
    internal static let okay = L10n.tr("Localizable", "alert.okay", fallback: "OK")
    internal enum ConnectionIssues {
      /// Es konnte keine Verbindung zum Dienst aufgebaut werden.
      internal static let message = L10n.tr("Localizable", "alert.connection_issues.message", fallback: "Es konnte keine Verbindung zum Dienst aufgebaut werden.")
      /// Verbindungsproblem
      internal static let title = L10n.tr("Localizable", "alert.connection_issues.title", fallback: "Verbindungsproblem")
    }
    internal enum InvalidSession {
      /// Bitte neu einloggen.
      internal static let message = L10n.tr("Localizable", "alert.invalid_session.message", fallback: "Bitte neu einloggen.")
      /// Ungültige Sitzung!
      internal static let title = L10n.tr("Localizable", "alert.invalid_session.title", fallback: "Ungültige Sitzung!")
    }
    internal enum OutdatedClient {
      /// Diese Version der App kann leider nicht mehr mit dem Server kommunizieren. Bitte das neuste Update installieren.
      internal static let message = L10n.tr("Localizable", "alert.outdated_client.message", fallback: "Diese Version der App kann leider nicht mehr mit dem Server kommunizieren. Bitte das neuste Update installieren.")
      /// Update erforderlich
      internal static let title = L10n.tr("Localizable", "alert.outdated_client.title", fallback: "Update erforderlich")
    }
    internal enum PushFailed {
      /// Einige Änderungen auf dem Gerät konnten nicht erfolgreich an die Website hochgeladen werden. Dies betrifft die folgenden Pendenzen:
      /// 
      /// %@
      internal static func message(_ p1: Any) -> String {
        return L10n.tr("Localizable", "alert.push_failed.message", String(describing: p1), fallback: "Einige Änderungen auf dem Gerät konnten nicht erfolgreich an die Website hochgeladen werden. Dies betrifft die folgenden Pendenzen:\n\n%@")
      }
      /// Fehler beim Hochladen!
      internal static let title = L10n.tr("Localizable", "alert.push_failed.title", fallback: "Fehler beim Hochladen!")
    }
    internal enum UnknownSyncError {
      /// Beim Aktualisieren ist ein unbekannter Fehler aufgetreten. Bitte später noch einmal versuchen.
      /// 
      /// Falls der Fehler bestehen bleibt, sollte der Text unter "Mehr Informationen…" dem Support behilflich sein
      internal static let message = L10n.tr("Localizable", "alert.unknown_sync_error.message", fallback: "Beim Aktualisieren ist ein unbekannter Fehler aufgetreten. Bitte später noch einmal versuchen.\n\nFalls der Fehler bestehen bleibt, sollte der Text unter \"Mehr Informationen…\" dem Support behilflich sein")
      /// Unbekannter Fehler!
      internal static let title = L10n.tr("Localizable", "alert.unknown_sync_error.title", fallback: "Unbekannter Fehler!")
    }
    internal enum UpgradeWiped {
      /// Willkommen in der neuen Version! Bitte erneut anmelden.
      internal static let message = L10n.tr("Localizable", "alert.upgrade_wiped.message", fallback: "Willkommen in der neuen Version! Bitte erneut anmelden.")
      /// App aktualisiert
      internal static let title = L10n.tr("Localizable", "alert.upgrade_wiped.title", fallback: "App aktualisiert")
    }
    internal enum Wiped {
      /// Die App wurde in den Originalzustand zurückversetzt. Bitte diese nun neu starten.
      internal static let message = L10n.tr("Localizable", "alert.wiped.message", fallback: "Die App wurde in den Originalzustand zurückversetzt. Bitte diese nun neu starten.")
      /// App schliessen
      internal static let quit = L10n.tr("Localizable", "alert.wiped.quit", fallback: "App schliessen")
      /// App zurückgesetzt!
      internal static let title = L10n.tr("Localizable", "alert.wiped.title", fallback: "App zurückgesetzt!")
    }
  }
  internal enum Button {
    /// Fertig
    internal static let done = L10n.tr("Localizable", "button.done", fallback: "Fertig")
  }
  internal enum ErrorViewer {
    /// Aktionen
    internal static let actionsSection = L10n.tr("Localizable", "error_viewer.actions_section", fallback: "Aktionen")
    /// An Entwickler schicken
    internal static let sendToDeveloper = L10n.tr("Localizable", "error_viewer.send_to_developer", fallback: "An Entwickler schicken")
    /// Details für Entwickler
    internal static let technicalDetailsSection = L10n.tr("Localizable", "error_viewer.technical_details_section", fallback: "Details für Entwickler")
    /// Fehlerdetails
    internal static let title = L10n.tr("Localizable", "error_viewer.title", fallback: "Fehlerdetails")
    internal enum PushFailed {
      /// Betroffene Pendenzen
      internal static let affectedIssuesSection = L10n.tr("Localizable", "error_viewer.push_failed.affected_issues_section", fallback: "Betroffene Pendenzen")
      /// Diese Änderungen verwerfen
      internal static let discardChanges = L10n.tr("Localizable", "error_viewer.push_failed.discard_changes", fallback: "Diese Änderungen verwerfen")
      /// Einige Änderungen auf dem Gerät konnten nicht erfolgreich an die Website hochgeladen werden.
      internal static let message = L10n.tr("Localizable", "error_viewer.push_failed.message", fallback: "Einige Änderungen auf dem Gerät konnten nicht erfolgreich an die Website hochgeladen werden.")
      internal enum ChangesDiscarded {
        /// Bitte nun erneut das Synchronisieren versuchen.
        internal static let message = L10n.tr("Localizable", "error_viewer.push_failed.changes_discarded.message", fallback: "Bitte nun erneut das Synchronisieren versuchen.")
        /// Änderungen verworfen!
        internal static let title = L10n.tr("Localizable", "error_viewer.push_failed.changes_discarded.title", fallback: "Änderungen verworfen!")
      }
      internal enum DiscardChanges {
        /// Diese Änderungen werden verworfen, um den Sync wiederherzustellen.
        internal static let confirm = L10n.tr("Localizable", "error_viewer.push_failed.discard_changes.confirm", fallback: "Diese Änderungen werden verworfen, um den Sync wiederherzustellen.")
      }
      internal enum MassDiscardChanges {
        /// Alle %@ Änderungen verwerfen
        internal static func action(_ p1: Any) -> String {
          return L10n.tr("Localizable", "error_viewer.push_failed.mass_discard_changes.action", String(describing: p1), fallback: "Alle %@ Änderungen verwerfen")
        }
        /// Es werden Änderungen an %@ Pendenzen verworfen.
        internal static func confirm(_ p1: Any) -> String {
          return L10n.tr("Localizable", "error_viewer.push_failed.mass_discard_changes.confirm", String(describing: p1), fallback: "Es werden Änderungen an %@ Pendenzen verworfen.")
        }
      }
      internal enum Stage {
        /// Neue Pendenz Hochladen
        internal static let create = L10n.tr("Localizable", "error_viewer.push_failed.stage.create", fallback: "Neue Pendenz Hochladen")
        /// Pendenz löschen
        internal static let deletion = L10n.tr("Localizable", "error_viewer.push_failed.stage.deletion", fallback: "Pendenz löschen")
        /// Bild Hochladen
        internal static let imageUpload = L10n.tr("Localizable", "error_viewer.push_failed.stage.image_upload", fallback: "Bild Hochladen")
        /// Details Hochladen
        internal static let patch = L10n.tr("Localizable", "error_viewer.push_failed.stage.patch", fallback: "Details Hochladen")
      }
    }
    internal enum UnknownError {
      /// Beim Aktualisieren ist ein unbekannter Fehler aufgetreten. Folgende Informationen sollten dem Support beim Diagnostizieren helfen:
      internal static let message = L10n.tr("Localizable", "error_viewer.unknown_error.message", fallback: "Beim Aktualisieren ist ein unbekannter Fehler aufgetreten. Folgende Informationen sollten dem Support beim Diagnostizieren helfen:")
    }
    internal enum WipeAllData {
      /// App zurücksetzen
      internal static let button = L10n.tr("Localizable", "error_viewer.wipe_all_data.button", fallback: "App zurücksetzen")
      /// Abbrechen
      internal static let cancel = L10n.tr("Localizable", "error_viewer.wipe_all_data.cancel", fallback: "Abbrechen")
      /// Alles löschen
      internal static let confirm = L10n.tr("Localizable", "error_viewer.wipe_all_data.confirm", fallback: "Alles löschen")
      /// Es werden alle Daten gelöscht, die nicht auf der Website sind. Fortfahren?
      internal static let warning = L10n.tr("Localizable", "error_viewer.wipe_all_data.warning", fallback: "Es werden alle Daten gelöscht, die nicht auf der Website sind. Fortfahren?")
    }
  }
  internal enum Issue {
    /// Unternehmer
    internal static let craftsman = L10n.tr("Localizable", "issue.craftsman", fallback: "Unternehmer")
    /// Name
    internal static let craftsmanName = L10n.tr("Localizable", "issue.craftsman_name", fallback: "Name")
    /// Beschreibung
    internal static let description = L10n.tr("Localizable", "issue.description", fallback: "Beschreibung")
    /// Im Abnahmemodus aufgenommen
    internal static let isClientMode = L10n.tr("Localizable", "issue.is_client_mode", fallback: "Im Abnahmemodus aufgenommen")
    /// Kein Unternehmer
    internal static let noCraftsman = L10n.tr("Localizable", "issue.no_craftsman", fallback: "Kein Unternehmer")
    /// Keine Beschreibung
    internal static let noDescription = L10n.tr("Localizable", "issue.no_description", fallback: "Keine Beschreibung")
    /// Status
    internal static let status = L10n.tr("Localizable", "issue.status", fallback: "Status")
    /// Gewerk
    internal static let trade = L10n.tr("Localizable", "issue.trade", fallback: "Gewerk")
    /// neu
    internal static let unregistered = L10n.tr("Localizable", "issue.unregistered", fallback: "neu")
    internal enum Status {
      /// Abgeschlossen
      internal static let closed = L10n.tr("Localizable", "issue.status.closed", fallback: "Abgeschlossen")
      /// Geschlossen von %@
      internal static func closedBy(_ p1: Any) -> String {
        return L10n.tr("Localizable", "issue.status.closed_by", String(describing: p1), fallback: "Geschlossen von %@")
      }
      /// Neu
      internal static let new = L10n.tr("Localizable", "issue.status.new", fallback: "Neu")
      /// Im Verzeichnis
      internal static let registered = L10n.tr("Localizable", "issue.status.registered", fallback: "Im Verzeichnis")
      /// Registriert von %@
      internal static func registeredBy(_ p1: Any) -> String {
        return L10n.tr("Localizable", "issue.status.registered_by", String(describing: p1), fallback: "Registriert von %@")
      }
      /// Zur Inspektion
      internal static let resolved = L10n.tr("Localizable", "issue.status.resolved", fallback: "Zur Inspektion")
      /// Umgesetzt von %@
      internal static func resolvedBy(_ p1: Any) -> String {
        return L10n.tr("Localizable", "issue.status.resolved_by", String(describing: p1), fallback: "Umgesetzt von %@")
      }
      /// [unbekannt]
      internal static let unknownEntity = L10n.tr("Localizable", "issue.status.unknown_entity", fallback: "[unbekannt]")
    }
  }
  internal enum Login {
    /// Einloggen
    internal static let connectToWebsite = L10n.tr("Localizable", "login.connect_to_website", fallback: "Einloggen")
    /// Jetzt registrieren
    internal static let register = L10n.tr("Localizable", "login.register", fallback: "Jetzt registrieren")
    internal enum Alert {
      internal enum LoginError {
        /// Beim Einloggen ist ein Fehler aufgetreten.
        internal static let message = L10n.tr("Localizable", "login.alert.login_error.message", fallback: "Beim Einloggen ist ein Fehler aufgetreten.")
        /// Unbekannter Fehler!
        internal static let title = L10n.tr("Localizable", "login.alert.login_error.title", fallback: "Unbekannter Fehler!")
      }
    }
    internal enum Placeholder {
      /// Website
      internal static let website = L10n.tr("Localizable", "login.placeholder.website", fallback: "Website")
    }
    internal enum Register {
      /// Noch nicht registriert?
      internal static let header = L10n.tr("Localizable", "login.register.header", fallback: "Noch nicht registriert?")
    }
    internal enum Scan {
      /// Abbrechen
      internal static let cancel = L10n.tr("Localizable", "login.scan.cancel", fallback: "Abbrechen")
      /// Dazu auf der Website auf „mit App verbinden“ klicken (in der Baustellenauswahl oben links).
      internal static let instructions = L10n.tr("Localizable", "login.scan.instructions", fallback: "Dazu auf der Website auf „mit App verbinden“ klicken (in der Baustellenauswahl oben links).")
      /// Login-Code Scannen
      internal static let title = L10n.tr("Localizable", "login.scan.title", fallback: "Login-Code Scannen")
    }
  }
  internal enum ManageStorage {
    /// Alle Bilder sind geladen.
    internal static let allImagesDownloaded = L10n.tr("Localizable", "manage_storage.all_images_downloaded", fallback: "Alle Bilder sind geladen.")
    /// %@ fehlende Bilder laden
    internal static func downloadAll(_ p1: Any) -> String {
      return L10n.tr("Localizable", "manage_storage.download_all", String(describing: p1), fallback: "%@ fehlende Bilder laden")
    }
    /// Um Daten zu sparen, werden nur Bilder von Pendenzen heruntergeladen, die noch offen sind oder seit weniger als 90 Tagen abgeschlossen sind. Bereits geladene Bilder können mit diesem Knopf lokal entfernt werden.
    internal static let purgeInfo = L10n.tr("Localizable", "manage_storage.purge_info", fallback: "Um Daten zu sparen, werden nur Bilder von Pendenzen heruntergeladen, die noch offen sind oder seit weniger als 90 Tagen abgeschlossen sind. Bereits geladene Bilder können mit diesem Knopf lokal entfernt werden.")
    /// Jetzt Platz einsparen
    internal static let purgeNow = L10n.tr("Localizable", "manage_storage.purge_now", fallback: "Jetzt Platz einsparen")
    /// Einsparbar:
    internal static let spacePurgeable = L10n.tr("Localizable", "manage_storage.space_purgeable", fallback: "Einsparbar:")
    /// Verwendet:
    internal static let spaceUsed = L10n.tr("Localizable", "manage_storage.space_used", fallback: "Verwendet:")
    /// Speicher verwalten
    internal static let title = L10n.tr("Localizable", "manage_storage.title", fallback: "Speicher verwalten")
    internal enum Section {
      /// Nach Baustelle
      internal static let bySite = L10n.tr("Localizable", "manage_storage.section.by_site", fallback: "Nach Baustelle")
      /// Insgesamt
      internal static let total = L10n.tr("Localizable", "manage_storage.section.total", fallback: "Insgesamt")
    }
  }
  internal enum Map {
    /// Der Bauplan konnte nicht geladen werden!
    internal static let couldNotLoad = L10n.tr("Localizable", "map.could_not_load", fallback: "Der Bauplan konnte nicht geladen werden!")
    /// Pendenz ohne Platzierung erfassen
    internal static let newUnpositionedIssue = L10n.tr("Localizable", "map.new_unpositioned_issue", fallback: "Pendenz ohne Platzierung erfassen")
    /// Wähle links einen Bereich aus, um hier den zugehörigen Bauplan zu sehen.
    internal static let noMapSelected = L10n.tr("Localizable", "map.no_map_selected", fallback: "Wähle links einen Bereich aus, um hier den zugehörigen Bauplan zu sehen.")
    /// Der Bereich "%@" hat keinen zugehörigen Bauplan.
    internal static func noPdf(_ p1: Any) -> String {
      return L10n.tr("Localizable", "map.no_pdf", String(describing: p1), fallback: "Der Bereich \"%@\" hat keinen zugehörigen Bauplan.")
    }
    /// Bauplan wird geladen…
    internal static let pdfLoading = L10n.tr("Localizable", "map.pdf_loading", fallback: "Bauplan wird geladen…")
    /// Bauplan
    internal static let title = L10n.tr("Localizable", "map.title", fallback: "Bauplan")
    internal enum IssueList {
      /// Details anzeigen
      internal static let showDetails = L10n.tr("Localizable", "map.issue_list.show_details", fallback: "Details anzeigen")
      /// Auf Bauplan anzeigen
      internal static let showInMap = L10n.tr("Localizable", "map.issue_list.show_in_map", fallback: "Auf Bauplan anzeigen")
      /// %@ Pendenzen offen; %@ insgesamt
      internal static func summary(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "map.issue_list.summary", String(describing: p1), String(describing: p2), fallback: "%@ Pendenzen offen; %@ insgesamt")
      }
      /// Filter aktiv: %@/%@ Pendenzen angezeigt
      internal static func summaryFiltered(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "map.issue_list.summary_filtered", String(describing: p1), String(describing: p2), fallback: "Filter aktiv: %@/%@ Pendenzen angezeigt")
      }
    }
    internal enum IssuePositioner {
      /// Abbrechen
      internal static let cancel = L10n.tr("Localizable", "map.issue_positioner.cancel", fallback: "Abbrechen")
      /// Weiter
      internal static let `continue` = L10n.tr("Localizable", "map.issue_positioner.continue", fallback: "Weiter")
    }
  }
  internal enum MapList {
    internal enum MapRemoved {
      /// Schliessen
      internal static let dismiss = L10n.tr("Localizable", "map_list.map_removed.dismiss", fallback: "Schliessen")
      /// Dieser Bereich existiert nicht mehr.
      internal static let message = L10n.tr("Localizable", "map_list.map_removed.message", fallback: "Dieser Bereich existiert nicht mehr.")
      /// Bereich entfernt!
      internal static let title = L10n.tr("Localizable", "map_list.map_removed.title", fallback: "Bereich entfernt!")
    }
    internal enum MapSummary {
      /// %@ offene Pendenzen
      internal static func openIssues(_ p1: Any) -> String {
        return L10n.tr("Localizable", "map_list.map_summary.open_issues", String(describing: p1), fallback: "%@ offene Pendenzen")
      }
    }
    internal enum RemovedFromMap {
      /// Schliessen
      internal static let dismiss = L10n.tr("Localizable", "map_list.removed_from_map.dismiss", fallback: "Schliessen")
      /// Diese Baustelle ist diesem Account nicht mehr zugänglich. Auf der Website kann dies unter "Baustelle auswählen" verändert werden.
      internal static let message = L10n.tr("Localizable", "map_list.removed_from_map.message", fallback: "Diese Baustelle ist diesem Account nicht mehr zugänglich. Auf der Website kann dies unter \"Baustelle auswählen\" verändert werden.")
      /// Kein Zugriff!
      internal static let title = L10n.tr("Localizable", "map_list.removed_from_map.title", fallback: "Kein Zugriff!")
    }
    internal enum Section {
      /// Untergeordnete Bereiche
      internal static let childMaps = L10n.tr("Localizable", "map_list.section.child_maps", fallback: "Untergeordnete Bereiche")
      /// Dieser Bereich
      internal static let thisMap = L10n.tr("Localizable", "map_list.section.this_map", fallback: "Dieser Bereich")
    }
  }
  internal enum Markup {
    /// Zeichnen
    internal static let title = L10n.tr("Localizable", "markup.title", fallback: "Zeichnen")
  }
  internal enum Register {
    /// Zurück zum Login
    internal static let backToLogin = L10n.tr("Localizable", "register.back_to_login", fallback: "Zurück zum Login")
    /// Registrieren
    internal static let createAccount = L10n.tr("Localizable", "register.create_account", fallback: "Registrieren")
    /// Auf anderer Website registrieren
    internal static let customizeWebsite = L10n.tr("Localizable", "register.customize_website", fallback: "Auf anderer Website registrieren")
    /// Es wird jetzt eine E-Mail verschickt, über welche der Account fertig erstellt werden kann. Möglicherweise wird die E-Mail als Spam einsortiert.
    internal static let emailExplanation = L10n.tr("Localizable", "register.email_explanation", fallback: "Es wird jetzt eine E-Mail verschickt, über welche der Account fertig erstellt werden kann. Möglicherweise wird die E-Mail als Spam einsortiert.")
    internal enum Alert {
      internal enum InvalidEmail {
        /// '%@' ist keine gültige E-Mail-Adresse.
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "register.alert.invalid_email.message", String(describing: p1), fallback: "'%@' ist keine gültige E-Mail-Adresse.")
        }
        /// Ungültige E-Mail!
        internal static let title = L10n.tr("Localizable", "register.alert.invalid_email.title", fallback: "Ungültige E-Mail!")
      }
      internal enum InvalidWebsite {
        /// '%@' ist keine gültige Web-Adresse.
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "register.alert.invalid_website.message", String(describing: p1), fallback: "'%@' ist keine gültige Web-Adresse.")
        }
        /// Ungültige Website!
        internal static let title = L10n.tr("Localizable", "register.alert.invalid_website.title", fallback: "Ungültige Website!")
      }
      internal enum UnknownError {
        /// Es ist beim Kommunizieren mit der Website ein unbekannter Fehler aufgetreten.
        /// 
        /// Falls der Fehler bestehen bleibt, könnte der folgende Text dem Support behilflich sein:
        /// %@
        internal static func message(_ p1: Any) -> String {
          return L10n.tr("Localizable", "register.alert.unknown_error.message", String(describing: p1), fallback: "Es ist beim Kommunizieren mit der Website ein unbekannter Fehler aufgetreten.\n\nFalls der Fehler bestehen bleibt, könnte der folgende Text dem Support behilflich sein:\n%@")
        }
        /// Fehler beim Registrieren!
        internal static let title = L10n.tr("Localizable", "register.alert.unknown_error.title", fallback: "Fehler beim Registrieren!")
      }
    }
    internal enum Placeholder {
      /// E-Mail
      internal static let email = L10n.tr("Localizable", "register.placeholder.email", fallback: "E-Mail")
      /// Website
      internal static let website = L10n.tr("Localizable", "register.placeholder.website", fallback: "Website")
    }
  }
  internal enum SiteList {
    /// Ausloggen
    internal static let logOut = L10n.tr("Localizable", "site_list.log_out", fallback: "Ausloggen")
    /// Speicher verwalten
    internal static let manageStorage = L10n.tr("Localizable", "site_list.manage_storage", fallback: "Speicher verwalten")
    /// Noch keine Daten geladen! Hier herunterziehen, um mit dem Server zu synchronisieren.
    internal static let refreshHint = L10n.tr("Localizable", "site_list.refresh_hint", fallback: "Noch keine Daten geladen! Hier herunterziehen, um mit dem Server zu synchronisieren.")
    /// Baustellen
    internal static let title = L10n.tr("Localizable", "site_list.title", fallback: "Baustellen")
    /// Willkommen, %@
    internal static func welcome(_ p1: Any) -> String {
      return L10n.tr("Localizable", "site_list.welcome", String(describing: p1), fallback: "Willkommen, %@")
    }
    internal enum ClientMode {
      /// Im Abnahmemodus werden nur die Pendenzen angezeigt, die auch im Abnahmemodus erfasst wurden.
      internal static let description = L10n.tr("Localizable", "site_list.client_mode.description", fallback: "Im Abnahmemodus werden nur die Pendenzen angezeigt, die auch im Abnahmemodus erfasst wurden.")
      /// Abnahmemodus
      internal static let title = L10n.tr("Localizable", "site_list.client_mode.title", fallback: "Abnahmemodus")
    }
    internal enum FileProgress {
      /// %@/%@ Pendenzbilder geladen…
      internal static func determinate(_ p1: Any, _ p2: Any) -> String {
        return L10n.tr("Localizable", "site_list.file_progress.determinate", String(describing: p1), String(describing: p2), fallback: "%@/%@ Pendenzbilder geladen…")
      }
      /// Pendenzbilder werden geladen…
      internal static let indeterminate = L10n.tr("Localizable", "site_list.file_progress.indeterminate", fallback: "Pendenzbilder werden geladen…")
    }
    internal enum SiteSummary {
      /// %@ offene Pendenzen
      internal static func openIssues(_ p1: Any) -> String {
        return L10n.tr("Localizable", "site_list.site_summary.open_issues", String(describing: p1), fallback: "%@ offene Pendenzen")
      }
      /// %@ insgesamt
      internal static func totalIssues(_ p1: Any) -> String {
        return L10n.tr("Localizable", "site_list.site_summary.total_issues", String(describing: p1), fallback: "%@ insgesamt")
      }
    }
  }
  internal enum Sync {
    internal enum Progress {
      /// Baustellenfotos laden: %@
      internal static func downloadingConstructionSiteFiles(_ p1: Any) -> String {
        return L10n.tr("Localizable", "sync.progress.downloading_construction_site_files", String(describing: p1), fallback: "Baustellenfotos laden: %@")
      }
      /// Grundrisse laden: %@
      internal static func downloadingMapFiles(_ p1: Any) -> String {
        return L10n.tr("Localizable", "sync.progress.downloading_map_files", String(describing: p1), fallback: "Grundrisse laden: %@")
      }
      /// Baustellen laden…
      internal static let fetchingTopLevelObjects = L10n.tr("Localizable", "sync.progress.fetching_top_level_objects", fallback: "Baustellen laden…")
      /// Pendenzen laden: %@
      internal static func pullingSiteData(_ p1: Any) -> String {
        return L10n.tr("Localizable", "sync.progress.pulling_site_data", String(describing: p1), fallback: "Pendenzen laden: %@")
      }
      /// Änderungen hochladen…
      internal static let pushingLocalChanges = L10n.tr("Localizable", "sync.progress.pushing_local_changes", fallback: "Änderungen hochladen…")
      internal enum FileProgress {
        /// %@/%@
        internal static func determinate(_ p1: Any, _ p2: Any) -> String {
          return L10n.tr("Localizable", "sync.progress.file_progress.determinate", String(describing: p1), String(describing: p2), fallback: "%@/%@")
        }
        /// fertig!
        internal static let done = L10n.tr("Localizable", "sync.progress.file_progress.done", fallback: "fertig!")
        /// …
        internal static let indeterminate = L10n.tr("Localizable", "sync.progress.file_progress.indeterminate", fallback: "…")
      }
    }
  }
  internal enum ViewIssue {
    /// Aktionen
    internal static let actions = L10n.tr("Localizable", "view_issue.actions", fallback: "Aktionen")
    /// Tippen, um ein Foto zu machen.
    internal static let cameraControlHint = L10n.tr("Localizable", "view_issue.camera_control_hint", fallback: "Tippen, um ein Foto zu machen.")
    /// Die Kamera konnte nicht aktiviert werden!
    internal static let couldNotActivateCamera = L10n.tr("Localizable", "view_issue.could_not_activate_camera", fallback: "Die Kamera konnte nicht aktiviert werden!")
    /// Unternehmer
    internal static let craftsman = L10n.tr("Localizable", "view_issue.craftsman", fallback: "Unternehmer")
    /// Beschreibung
    internal static let description = L10n.tr("Localizable", "view_issue.description", fallback: "Beschreibung")
    /// Details
    internal static let details = L10n.tr("Localizable", "view_issue.details", fallback: "Details")
    /// Foto
    internal static let image = L10n.tr("Localizable", "view_issue.image", fallback: "Foto")
    /// Im Abnahmemodus aufgenommen
    internal static let isClientMode = L10n.tr("Localizable", "view_issue.is_client_mode", fallback: "Im Abnahmemodus aufgenommen")
    /// Auf Foto zeichnen
    internal static let markup = L10n.tr("Localizable", "view_issue.markup", fallback: "Auf Foto zeichnen")
    /// Keine passenden Vorschläge
    internal static let noSuggestions = L10n.tr("Localizable", "view_issue.no_suggestions", fallback: "Keine passenden Vorschläge")
    /// Kein Gewerk
    internal static let noTrade = L10n.tr("Localizable", "view_issue.no_trade", fallback: "Kein Gewerk")
    /// Erneut versuchen
    internal static let retryCamera = L10n.tr("Localizable", "view_issue.retry_camera", fallback: "Erneut versuchen")
    /// Diese Pendenz wurde vom Unternehmer als umgesetzt markiert.
    internal static let reviewExplanation = L10n.tr("Localizable", "view_issue.review_explanation", fallback: "Diese Pendenz wurde vom Unternehmer als umgesetzt markiert.")
    /// Neue Pendenz
    internal static let titleCreating = L10n.tr("Localizable", "view_issue.title_creating", fallback: "Neue Pendenz")
    /// Pendenz bearbeiten
    internal static let titleEditing = L10n.tr("Localizable", "view_issue.title_editing", fallback: "Pendenz bearbeiten")
    /// Details
    internal static let titleViewing = L10n.tr("Localizable", "view_issue.title_viewing", fallback: "Details")
    internal enum Action {
      /// Pendenz schliessen
      internal static let close = L10n.tr("Localizable", "view_issue.action.close", fallback: "Pendenz schliessen")
      /// Pendenz wiedereröffnen
      internal static let reopen = L10n.tr("Localizable", "view_issue.action.reopen", fallback: "Pendenz wiedereröffnen")
      /// Markierung zurücksetzen
      internal static let resetResolution = L10n.tr("Localizable", "view_issue.action.reset_resolution", fallback: "Markierung zurücksetzen")
    }
    internal enum CouldNotOpenLibrary {
      /// Um die Fotoauswahl zu öffnen, braucht diese App in den Einstellungen Zugriff auf deine Fotos.
      internal static let message = L10n.tr("Localizable", "view_issue.could_not_open_library.message", fallback: "Um die Fotoauswahl zu öffnen, braucht diese App in den Einstellungen Zugriff auf deine Fotos.")
      /// Fotoauswahl nicht möglich!
      internal static let title = L10n.tr("Localizable", "view_issue.could_not_open_library.title", fallback: "Fotoauswahl nicht möglich!")
    }
    internal enum CouldNotSaveImage {
      /// Das Bild konnte nicht abgespeichert werden!
      internal static let title = L10n.tr("Localizable", "view_issue.could_not_save_image.title", fallback: "Das Bild konnte nicht abgespeichert werden!")
    }
    internal enum CouldNotTakePicture {
      /// Fotoaufnahme fehlgeschlagen!
      internal static let title = L10n.tr("Localizable", "view_issue.could_not_take_picture.title", fallback: "Fotoaufnahme fehlgeschlagen!")
    }
    internal enum ImagePlaceholder {
      /// Bild noch nicht geladen.
      internal static let loading = L10n.tr("Localizable", "view_issue.image_placeholder.loading", fallback: "Bild noch nicht geladen.")
      /// Kein Foto gesetzt
      internal static let notSet = L10n.tr("Localizable", "view_issue.image_placeholder.not_set", fallback: "Kein Foto gesetzt")
    }
    internal enum IsClientMode {
      /// Nein
      internal static let `false` = L10n.tr("Localizable", "view_issue.is_client_mode.false", fallback: "Nein")
      /// Ja
      internal static let `true` = L10n.tr("Localizable", "view_issue.is_client_mode.true", fallback: "Ja")
    }
    internal enum SelectCraftsman {
      /// Kein Unternehmer
      internal static let `none` = L10n.tr("Localizable", "view_issue.select_craftsman.none", fallback: "Kein Unternehmer")
      /// Unternehmer
      internal static let title = L10n.tr("Localizable", "view_issue.select_craftsman.title", fallback: "Unternehmer")
    }
    internal enum SelectTrade {
      /// Kein Gewerk
      internal static let `none` = L10n.tr("Localizable", "view_issue.select_trade.none", fallback: "Kein Gewerk")
      /// Gewerke
      internal static let title = L10n.tr("Localizable", "view_issue.select_trade.title", fallback: "Gewerke")
    }
  }
  internal enum ViewOptions {
    /// Abnahmemodus
    internal static let clientMode = L10n.tr("Localizable", "view_options.client_mode", fallback: "Abnahmemodus")
    /// Ansicht Anpassen
    internal static let title = L10n.tr("Localizable", "view_options.title", fallback: "Ansicht Anpassen")
    internal enum CraftsmanFilter {
      /// Alle verstecken
      internal static let hideAll = L10n.tr("Localizable", "view_options.craftsman_filter.hide_all", fallback: "Alle verstecken")
      /// Alle anzeigen
      internal static let showAll = L10n.tr("Localizable", "view_options.craftsman_filter.show_all", fallback: "Alle anzeigen")
      /// Nach Unternehmer Filtern
      internal static let title = L10n.tr("Localizable", "view_options.craftsman_filter.title", fallback: "Nach Unternehmer Filtern")
      internal enum Label {
        /// alle sichtbar
        internal static let allVisible = L10n.tr("Localizable", "view_options.craftsman_filter.label.all_visible", fallback: "alle sichtbar")
        /// Unternehmer
        internal static let title = L10n.tr("Localizable", "view_options.craftsman_filter.label.title", fallback: "Unternehmer")
        /// %@ sichtbar
        internal static func visibleCount(_ p1: Any) -> String {
          return L10n.tr("Localizable", "view_options.craftsman_filter.label.visible_count", String(describing: p1), fallback: "%@ sichtbar")
        }
      }
    }
    internal enum StatusFilter {
      /// Es werden alle Pendenzen angezeigt.
      internal static let allSelected = L10n.tr("Localizable", "view_options.status_filter.all_selected", fallback: "Es werden alle Pendenzen angezeigt.")
      /// Es werden keine Pendenzen angezeigt.
      internal static let noneSelected = L10n.tr("Localizable", "view_options.status_filter.none_selected", fallback: "Es werden keine Pendenzen angezeigt.")
      /// Es werden nur Pendenzen mit einem der ausgewählten Status angezeigt.
      internal static let someSelected = L10n.tr("Localizable", "view_options.status_filter.some_selected", fallback: "Es werden nur Pendenzen mit einem der ausgewählten Status angezeigt.")
      /// Filter nach Status
      internal static let title = L10n.tr("Localizable", "view_options.status_filter.title", fallback: "Filter nach Status")
    }
  }
}
// swiftlint:enable explicit_type_interface function_parameter_count identifier_name line_length
// swiftlint:enable nesting type_body_length type_name vertical_whitespace_opening_braces

// MARK: - Implementation Details

extension L10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type

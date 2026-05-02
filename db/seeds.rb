# db/seeds.rb
# Normaler Aufruf:  bin/rails db:seed
# Demo-Datensatz:   DEMO=1 bin/rails db:seed
#
# DEMO=1 löscht alle bestehenden Daten und legt einen vollständigen
# Muster-Kindergarten mit Betreuer:innen, Gruppen, Kindern und Eltern an.

return unless ENV["DEMO"] == "1"

puts ""
puts "╔══════════════════════════════════════════════╗"
puts "║  Mikiwa — Demo-Datensatz wird aufgebaut …    ║"
puts "╚══════════════════════════════════════════════╝"
puts ""

# ── Bestehende Daten bereinigen (Reihenfolge wegen FK-Constraints) ──────────
print "  Bereinige bestehende Daten … "
[ ParentChild, MedicalNote, EmergencyContact, Child,
 Group, KindergartenYear, Session, User ].each(&:delete_all)
puts "✓"

DEMO_PW = "changeme12345678"

# ── Hilfsmethoden ────────────────────────────────────────────────────────────

def demo_parent(email:, first_name:, last_name:, phone: nil, active: true)
  User.create!(
    email:                    email,
    password:                 DEMO_PW,
    first_name:               first_name,
    last_name:                last_name,
    role:                     "parent",
    phone:                    phone,
    invitation_sent_at:       active ? 3.weeks.ago : 5.days.ago,
    magic_link_token_version: active ? 1 : 0
  )
end

def demo_child(group:, year:, first_name:, last_name:, nickname: nil,
               date_of_birth:, photo: true, health_insurer: "ÖGK", insurance_number: nil,
               parents: [], emergency_contacts: [], medical: [])
  child = Child.create!(
    first_name:           first_name,
    last_name:            last_name,
    nickname:             nickname,
    date_of_birth:        date_of_birth,
    group:                group,
    kindergarten_year:    year,
    photo_consent:        photo,
    health_insurer:       health_insurer,
    insurance_number:     insurance_number
  )

  parents.each { |p| ParentChild.create!(user: p, child: child) }

  emergency_contacts.each_with_index do |(name, relationship, phone), pos|
    child.emergency_contacts.create!(name: name, relationship: relationship, phone: phone, position: pos + 1)
  end

  medical.each do |(type, content)|
    child.medical_notes.create!(note_type: type, content: content)
  end

  child
end

# ── Betreuer:innen & Admin ───────────────────────────────────────────────────
puts "  Betreuer:innen …"

User.create!(
  email: "sabine@mikiwa.local", password: DEMO_PW,
  first_name: "Sabine", last_name: "Gruber",
  role: "admin", phone: "0664 100 2030"
)

User.create!(
  email: "klaus@mikiwa.local", password: DEMO_PW,
  first_name: "Klaus", last_name: "Maier",
  role: "caretaker", phone: "0664 200 3040"
)

User.create!(
  email: "tine@mikiwa.local", password: DEMO_PW,
  first_name: "Tine", last_name: "Ulbing",
  role: "caretaker", phone: "0660 300 4050"
)

# ── Kindergartenjahre ────────────────────────────────────────────────────────
puts "  Kindergartenjahre …"

KindergartenYear.create!(
  label:      "2024/2025",
  start_date: Date.new(2024, 9, 2),
  end_date:   Date.new(2025, 7, 11),
  active:     false
)

year = KindergartenYear.create!(
  label:      "2025/2026",
  start_date: Date.new(2025, 9, 1),
  end_date:   Date.new(2026, 7, 10),
  active:     true
)

# ── Gruppen ──────────────────────────────────────────────────────────────────
puts "  Gruppen …"

sunflowers = Group.create!(
  name: "Sonnenblumen", color: "#D97706",
  description: "Die älteste Gruppe – Kinder im vorletzten und letzten Kindergartenjahr."
)

ladybugs = Group.create!(
  name: "Marienkäfer", color: "#DC2626",
  description: "Mittlere Altersgruppe, aktiv und neugierig."
)

butterflies = Group.create!(
  name: "Schmetterlinge", color: "#7C3AED",
  description: "Die jüngste Gruppe – Eingewöhnung und erste große Schritte."
)

# ── Eltern-Accounts ──────────────────────────────────────────────────────────
puts "  Eltern-Accounts …"

# Sonnenblumen-Familien
mama_gruber   = demo_parent(email: "anna.gruber@example.at",    first_name: "Anna",      last_name: "Gruber",   phone: "0699 111 2233")
papa_gruber   = demo_parent(email: "stefan.gruber@example.at",  first_name: "Stefan",    last_name: "Gruber",   phone: "0699 444 5566")
mama_bauer    = demo_parent(email: "lisa.bauer@example.at",     first_name: "Lisa",      last_name: "Bauer",    phone: "0664 987 6543")
mama_steiner  = demo_parent(email: "eva.steiner@example.at",    first_name: "Eva",       last_name: "Steiner",  phone: "0677 222 3344")
mama_maier    = demo_parent(email: "maria.maier@example.at",    first_name: "Maria",     last_name: "Maier",    phone: "0650 333 4455")
mama_kainz    = demo_parent(email: "barbara.kainz@example.at",  first_name: "Barbara",   last_name: "Kainz",    phone: "0699 555 0011")

# Marienkäfer-Familien
mama_winkler  = demo_parent(email: "petra.winkler@example.at",  first_name: "Petra",     last_name: "Winkler",  phone: "0677 333 4455")
papa_brunner  = demo_parent(email: "markus.brunner@example.at", first_name: "Markus",    last_name: "Brunner",  phone: "0699 555 6677")
mama_fuchs    = demo_parent(email: "karin.fuchs@example.at",    first_name: "Karin",     last_name: "Fuchs",    phone: "0660 444 5566")
mama_c_huber  = demo_parent(email: "christine.huber@example.at", first_name: "Christine", last_name: "Huber",   phone: "0660 555 6677")
mama_pichler  = demo_parent(email: "monika.pichler@example.at", first_name: "Monika",    last_name: "Pichler",  phone: "0677 666 7788", active: false)

# Schmetterlinge-Familien
mama_hofer    = demo_parent(email: "julia.hofer@example.at",    first_name: "Julia",     last_name: "Hofer",    phone: "0664 666 7788")
mama_schuster = demo_parent(email: "nina.schuster@example.at",  first_name: "Nina",      last_name: "Schuster", phone: "0699 777 8899")
mama_berger   = demo_parent(email: "andrea.berger@example.at",  first_name: "Andrea",    last_name: "Berger",   phone: "0660 888 9900", active: false)
mama_ziegler  = demo_parent(email: "sandra.ziegler@example.at", first_name: "Sandra",    last_name: "Ziegler",  phone: "0677 999 0011")

# ── Kinder – Gruppe Sonnenblumen ─────────────────────────────────────────────
puts "  Kinder (Sonnenblumen) …"

demo_child(
  group: sunflowers, year: year,
  first_name: "Emma", last_name: "Gruber",
  date_of_birth: Date.new(2021, 3, 12),
  health_insurer: "ÖGK", insurance_number: "3456789012",
  photo: true,
  parents: [ mama_gruber, papa_gruber ],
  emergency_contacts: [
    [ "Anna Gruber",   "Mutter", "0699 111 2233" ],
    [ "Stefan Gruber", "Vater",  "0699 444 5566" ]
  ],
  medical: [
    [ "allergy",
     "Erdnuss- und Baumnussallergie – kein Kontakt mit Nüssen oder nusshaltigen Produkten. " \
     "Epinephrin-Autoinjektor (EpiPen) befindet sich in der Kindergartentasche. " \
     "Bei Reaktion sofort Eltern kontaktieren und Notarzt rufen." ]
  ]
)

demo_child(
  group: sunflowers, year: year,
  first_name: "Noah", last_name: "Bauer", nickname: "Nobi",
  date_of_birth: Date.new(2020, 7, 7),
  health_insurer: "ÖGK", insurance_number: "1234567890",
  photo: true,
  parents: [ mama_bauer ],
  emergency_contacts: [
    [ "Lisa Bauer",     "Mutter",     "0664 987 6543" ],
    [ "Elfriede Bauer", "Großmutter", "0660 123 4567" ]
  ],
  medical: [
    [ "medication",
     "Allergisches Asthma – Salbutamol-Inhalator (Ventolin) bei akutem Anfall. " \
     "Inhalator liegt im Büro (beschriftete Box im Kühlschrank). " \
     "Eltern bei jedem Einsatz bitte sofort informieren." ]
  ]
)

demo_child(
  group: sunflowers, year: year,
  first_name: "Mia", last_name: "Steiner",
  date_of_birth: Date.new(2021, 11, 28),
  health_insurer: "BVA", insurance_number: "9876543210",
  photo: false,
  parents: [ mama_steiner ],
  emergency_contacts: [
    [ "Eva Steiner",   "Mutter", "0677 222 3344" ],
    [ "Josef Steiner", "Vater",  "0664 345 6789" ]
  ]
)

demo_child(
  group: sunflowers, year: year,
  first_name: "Luca", last_name: "Maier",
  date_of_birth: Date.new(2021, 1, 15),
  health_insurer: "ÖGK", insurance_number: "2345678901",
  photo: true,
  parents: [ mama_maier ],
  emergency_contacts: [
    [ "Maria Maier", "Mutter", "0650 333 4455" ],
    [ "Josef Maier", "Opa",    "0664 567 8901" ]
  ]
)

demo_child(
  group: sunflowers, year: year,
  first_name: "Sophie", last_name: "Kainz",
  date_of_birth: Date.new(2020, 9, 22),
  health_insurer: "SVS", insurance_number: "8765432109",
  photo: true,
  parents: [ mama_kainz ],
  emergency_contacts: [
    [ "Barbara Kainz", "Mutter", "0699 555 0011" ],
    [ "Thomas Kainz",  "Vater",  "0699 555 0022" ]
  ]
)

# ── Kinder – Gruppe Marienkäfer ──────────────────────────────────────────────
puts "  Kinder (Marienkäfer) …"

demo_child(
  group: ladybugs, year: year,
  first_name: "Hannah", last_name: "Winkler",
  date_of_birth: Date.new(2022, 4, 14),
  health_insurer: "ÖGK",
  photo: true,
  parents: [ mama_winkler ],
  emergency_contacts: [
    [ "Petra Winkler",    "Mutter",     "0677 333 4455" ],
    [ "Gertrude Winkler", "Großmutter", "0664 890 1234" ]
  ]
)

demo_child(
  group: ladybugs, year: year,
  first_name: "Max", last_name: "Brunner", nickname: "Maxi",
  date_of_birth: Date.new(2022, 6, 3),
  health_insurer: "ÖGK", insurance_number: "5678901234",
  photo: true,
  parents: [ papa_brunner ],
  emergency_contacts: [
    [ "Markus Brunner", "Vater",  "0699 555 6677" ],
    [ "Helga Brunner",  "Mutter", "0677 444 5566" ]
  ],
  medical: [
    [ "allergy",
     "Erdbeerallergie – Kontakt mit frischen Erdbeeren oder erdbeerhaltigen Produkten vermeiden. " \
     "Antihistaminikum (Cetirizin-Tropfen 10 mg/ml) liegt im Büro. " \
     "Bei stärkerer Reaktion (Nesselausschlag, Atemnot) sofort Eltern und Notarzt kontaktieren." ]
  ]
)

demo_child(
  group: ladybugs, year: year,
  first_name: "Lea", last_name: "Fuchs",
  date_of_birth: Date.new(2022, 2, 19),
  health_insurer: "BVA",
  photo: false,
  parents: [ mama_fuchs ],
  emergency_contacts: [
    [ "Karin Fuchs", "Mutter", "0660 444 5566" ]
  ],
  medical: [
    [ "special_note",
     "Laktoseintoleranz – keine Milch, keinen Käse, keinen Joghurt bei Jause. " \
     "Eltern bringen täglich laktosefreie Jause mit. " \
     "Bitte keine milchhaltigen Snacks anbieten, auch keine Schokolade mit Vollmilch." ]
  ]
)

demo_child(
  group: ladybugs, year: year,
  first_name: "Jonas", last_name: "Huber",
  date_of_birth: Date.new(2022, 8, 30),
  health_insurer: "ÖGK", insurance_number: "6789012345",
  photo: true,
  parents: [ mama_c_huber ],
  emergency_contacts: [
    [ "Christine Huber", "Mutter", "0660 555 6677" ],
    [ "Peter Huber",     "Vater",  "0699 666 7788" ]
  ]
)

demo_child(
  group: ladybugs, year: year,
  first_name: "Selina", last_name: "Pichler",
  date_of_birth: Date.new(2021, 12, 11),
  health_insurer: "ÖGK",
  photo: true,
  parents: [ mama_pichler ],
  emergency_contacts: [
    [ "Monika Pichler", "Mutter", "0677 666 7788" ],
    [ "Ernst Pichler",  "Opa",    "0664 777 8899" ]
  ]
)

# ── Kinder – Gruppe Schmetterlinge ───────────────────────────────────────────
puts "  Kinder (Schmetterlinge) …"

demo_child(
  group: butterflies, year: year,
  first_name: "Felix", last_name: "Hofer",
  date_of_birth: Date.new(2023, 3, 5),
  health_insurer: "ÖGK", insurance_number: "7890123456",
  photo: true,
  parents: [ mama_hofer ],
  emergency_contacts: [
    [ "Julia Hofer",  "Mutter", "0664 666 7788" ],
    [ "Thomas Hofer", "Vater",  "0664 666 9900" ]
  ],
  medical: [
    [ "special_note",
     "Neurodermitis – bei sichtbaren Hautveränderungen oder starkem Juckreiz Eltern informieren. " \
     "Feuchtigkeitscreme (Excipial Repair) liegt in der Kindergartentasche. " \
     "Kein Wollkontakt am Bauch. Bei Ausflügen bitte Sonnencreme auftragen (liegt ebenfalls in der Tasche)." ]
  ]
)

demo_child(
  group: butterflies, year: year,
  first_name: "Laura", last_name: "Schuster",
  date_of_birth: Date.new(2023, 1, 22),
  health_insurer: "ÖGK",
  photo: true,
  parents: [ mama_schuster ],
  emergency_contacts: [
    [ "Nina Schuster", "Mutter",     "0699 777 8899" ],
    [ "Karl Schuster", "Großvater",  "0664 234 5678" ]
  ]
)

demo_child(
  group: butterflies, year: year,
  first_name: "Tom", last_name: "Berger", nickname: "Tommy",
  date_of_birth: Date.new(2023, 10, 14),
  health_insurer: "BVA",
  photo: true,
  parents: [ mama_berger ],
  emergency_contacts: [
    [ "Andrea Berger",  "Mutter", "0660 888 9900" ],
    [ "Michael Berger", "Vater",  "0660 888 1100" ]
  ]
)

demo_child(
  group: butterflies, year: year,
  first_name: "Klara", last_name: "Ziegler",
  date_of_birth: Date.new(2023, 5, 25),
  health_insurer: "ÖGK",
  photo: false,
  parents: [ mama_ziegler ],
  emergency_contacts: [
    [ "Sandra Ziegler", "Mutter", "0677 999 0011" ]
  ]
)

# ── Zusammenfassung ──────────────────────────────────────────────────────────
puts ""
puts "  ┌──────────────────────────────────────────────┐"
puts "  │  Demo-Datensatz erfolgreich erstellt ✓        │"
puts "  ├──────────────────────────────────────────────┤"
printf "  │  Betreuer:innen    %-3s                        │\n", User.staff.count
printf "  │  Eltern-Accounts   %-3s                        │\n", User.parents.count
printf "  │  Kindergartenjahre %-3s                        │\n", KindergartenYear.count
printf "  │  Gruppen           %-3s                        │\n", Group.count
printf "  │  Kinder            %-3s                        │\n", Child.count
printf "  │  Notfallkontakte   %-3s                        │\n", EmergencyContact.count
printf "  │  Med. Hinweise     %-3s                        │\n", MedicalNote.count
puts "  ├──────────────────────────────────────────────┤"
puts "  │  Login  sabine@mikiwa.local                   │"
puts "  │  PW     changeme12345678                     │"
puts "  └──────────────────────────────────────────────┘"
puts ""

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
[
  Vote, PollOption, Poll,
  InboxEntry, MessageGroup, Message,
  GalleryGroup, Gallery,
  CalendarEventGroup, CalendarEvent,
  AttendanceEntry, AttendanceList,
  ShoppingItem, ShoppingList,
  MealCourse, MealEntry,
  ParentChild, MedicalNote, EmergencyContact, Child,
  Group, KindergartenYear, Session, User
].each(&:delete_all)
puts "✓"

DEMO_PW = "changeme12345678"

# ── Hilfsmethoden ────────────────────────────────────────────────────────────

def demo_parent(email:, first_name:, last_name:, phone:, active: true)
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

# ── Speiseplan – aktuelle + nächste 3 Wochen ─────────────────────────────────
puts "  Speiseplan …"

cook = User.find_by(email: "klaus@mikiwa.local") || User.staff.first

# 4 Wochen mit jeweils Mo-Fr.
# Pro Tag bis zu vier optionale Speisen-Slots (starter / main / dessert / extra),
# jeweils mit Diät-Tag (standard / vegetarian / vegan).
# Format: { starter: [name, dietary], main: [name, dietary], dessert: ..., extra: ..., notes: "…" }
weekly_menus = [
  # ── Woche 1 ──
  [
    { main:    [ "Spaghetti Bolognese",            "standard" ],
      starter: [ "Tomaten-Reissuppe",              "vegan" ],
      dessert: [ "Apfelkompott",                   "vegan" ],
      notes:   "Vegetarische Bolognese mit Linsen auf Wunsch" },
    { main:    [ "Cremige Gemüsesuppe mit Kartoffeln", "vegetarian" ],
      extra:   [ "Vollkornbrot",                   "vegan" ] },
    { main:    [ "Hühnerschnitzel mit Reis",       "standard" ],
      starter: [ "Karottensalat",                  "vegan" ],
      dessert: [ "Joghurt mit Honig",              "vegetarian" ] },
    { main:    [ "Kärntner Kasnudeln",             "vegetarian" ],
      starter: [ "Blattsalat mit Kürbiskernöl",    "vegan" ],
      notes:   "Hausgemacht von Klaus & Tine" },
    { main:    [ "Fischstäbchen mit Erdäpfelpüree", "standard" ],
      dessert: [ "Apfelmus",                       "vegan" ] }
  ],
  # ── Woche 2 ──
  [
    { starter: [ "Cremige Karottensuppe",          "vegetarian" ],
      main:    [ "Hirseauflauf mit Gemüse",        "vegetarian" ],
      dessert: [ "Vanillepudding",                 "vegetarian" ] },
    { main:    [ "Erdäpfelpuffer mit Apfelmus",    "vegetarian" ],
      extra:   [ "Joghurt-Dip",                    "vegetarian" ] },
    { starter: [ "Bunter Salat",                   "vegan" ],
      main:    [ "Lasagne mit Zucchini und Spinat", "vegetarian" ],
      dessert: [ "Frische Beeren",                 "vegan" ] },
    { main:    [ "Kürbis-Risotto",                 "vegan" ],
      notes:   "Saisonal aus dem Bio-Garten" },
    { starter: [ "Tomaten-Mozzarella-Salat",       "vegetarian" ],
      main:    [ "Pizza mit Tomaten und Mozzarella", "vegetarian" ],
      dessert: [ "Eis am Stiel",                   "vegan" ],
      notes:   "Pizza-Tag – immer ein Highlight" }
  ],
  # ── Woche 3 ──
  [
    { starter: [ "Grießnockerlsuppe",              "vegetarian" ],
      main:    [ "Reisfleisch mit Erbsen",         "standard" ] },
    { main:    [ "Linseneintopf mit Wienerle",     "standard" ],
      extra:   [ "Vollkornbrot",                   "vegan" ],
      notes:   "Vegane Wiener auf Wunsch" },
    { main:    [ "Palatschinken mit Marillenmarmelade", "vegetarian" ],
      starter: [ "Klare Gemüsebrühe",              "vegan" ],
      notes:   "Marillen aus eigenem Garten" },
    { starter: [ "Karotten-Ingwer-Suppe",          "vegan" ],
      main:    [ "Käsespätzle mit Röstzwiebeln",   "vegetarian" ],
      dessert: [ "Topfencreme",                    "vegetarian" ] },
    { main:    [ "Bunte Gemüsepfanne mit Quinoa",  "vegan" ],
      dessert: [ "Bananenbrot",                    "vegetarian" ] }
  ],
  # ── Woche 4 ──
  [
    { starter: [ "Tomatensuppe",                   "vegan" ],
      main:    [ "Hähnchen-Gemüsepfanne",          "standard" ],
      extra:   [ "Reis",                           "vegan" ] },
    { main:    [ "Hirseauflauf mit Karotten und Lauch", "vegetarian" ],
      dessert: [ "Apfelstücke",                    "vegan" ] },
    { starter: [ "Feldsalat",                      "vegan" ],
      main:    [ "Fischfilet mit Petersilkartoffeln", "standard" ],
      notes:   "Aus heimischer Aquakultur" },
    { main:    [ "Kärntner Kasnudeln",             "vegetarian" ],
      dessert: [ "Mohnnudeln",                     "vegetarian" ] },
    { starter: [ "Bauernbrot mit Aufstrich",       "vegan" ],
      main:    [ "Apfelkücherl mit Vanillesoße",   "vegetarian" ],
      notes:   "Süßer Wochenausklang" }
  ]
]

monday_this_week = Date.current.beginning_of_week(:monday)
groups = [ sunflowers, ladybugs, butterflies ]
course_keys = MealCourse::COURSE_TYPES.map(&:to_sym)  # [:starter, :main, :dessert, :extra]

meal_count = 0
course_count = 0
weekly_menus.each_with_index do |menu, week_offset|
  monday = monday_this_week + (week_offset * 7).days
  menu.each_with_index do |day_plan, day_offset|
    date = monday + day_offset.days
    groups.each do |group|
      courses_attrs = course_keys.each_with_index.filter_map do |key, idx|
        spec = day_plan[key]
        next unless spec
        name, dietary = spec
        { course_type: key.to_s, name: name, dietary: dietary || "standard", position: idx }
      end

      MealEntry.create!(
        date:                    date,
        notes:                   day_plan[:notes],
        group:                   group,
        kindergarten_year:       year,
        created_by:              cook,
        meal_courses_attributes: courses_attrs
      )
      meal_count   += 1
      course_count += courses_attrs.size
    end
  end
end

# ── Veranstaltungen & Kalendereinträge ───────────────────────────────────────
puts "  Veranstaltungen …"

sabine = User.find_by(email: "sabine@mikiwa.local")
today  = Date.current

# Hilfsmethode: Event/CalendarEvent mit Gruppen in einem Schritt anlegen
def create_cal_event(model_class, groups, **attrs)
  ev = model_class.new(attrs)
  groups.each { |g| ev.calendar_event_groups.build(group: g) }
  ev.save!
  ev
end

# Veranstaltungen (event_type = "veranstaltung", über Event-Model)
sommerfest = create_cal_event(Event, [ sunflowers, ladybugs, butterflies ],
  title:             "Sommerfest",
  start_date:        today + 24.days,
  all_day:           true,
  location:          "Kindergarten-Garten",
  description:       "Unser großes Jahresfest mit Grillen, Spielen und Musik. " \
                     "Alle Familien sind herzlich eingeladen!",
  kindergarten_year: year,
  created_by:        sabine,
  status:            "aktiv"
)

nikolaus = create_cal_event(Event, [ sunflowers, ladybugs, butterflies ],
  title:             "Nikolausfeier",
  start_date:        today.change(month: 12, day: 5) > today ?
                       today.change(month: 12, day: 5) :
                       today.change(year: today.year + 1, month: 12, day: 5),
  all_day:           true,
  location:          "Gruppenraum",
  description:       "Der Nikolaus kommt zu Besuch und bringt für jedes Kind ein kleines Päckchen.",
  kindergarten_year: year,
  created_by:        sabine,
  status:            "aktiv"
)

fruehlingsfest = create_cal_event(Event, [ sunflowers, ladybugs ],
  title:             "Frühlingsfest",
  start_date:        today - 14.days,
  all_day:           true,
  location:          "Kindergarten-Garten",
  description:       "Wir feiern den Frühling mit Tänzen, Basteln und einem bunten Buffet.",
  kindergarten_year: year,
  created_by:        sabine,
  status:            "aktiv"
)

# Allgemeine Kalendereinträge (event_type = "event")
elternsprechtag = create_cal_event(CalendarEvent, [ sunflowers, ladybugs, butterflies ],
  title:             "Elternsprechtag",
  event_type:        "event",
  start_date:        today + 10.days,
  all_day:           false,
  start_time:        "15:30",
  location:          "Kindergarten – Büro Sabine Gruber",
  description:       "Individuelle Termine bitte direkt mit der Gruppenleitung vereinbaren.",
  kindergarten_year: year,
  created_by:        sabine,
  status:            "aktiv"
)

ausflug = create_cal_event(CalendarEvent, [ sunflowers, ladybugs ],
  title:             "Ausflug: Zoo Salzburg",
  event_type:        "event",
  start_date:        today + 7.days,
  all_day:           true,
  location:          "Salzburger Tiergarten Hellbrunn",
  description:       "Ganztagesausflug für die Gruppen Sonnenblumen und Marienkäfer. " \
                     "Bitte Jause & Regenjacke einpacken.",
  kindergarten_year: year,
  created_by:        sabine,
  status:            "aktiv"
)

create_cal_event(CalendarEvent, [ butterflies ],
  title:             "Elternabend – Gruppe Schmetterlinge",
  event_type:        "event",
  start_date:        today + 5.days,
  all_day:           false,
  start_time:        "18:30",
  location:          "Gruppenraum Schmetterlinge",
  description:       "Themen: Eingewöhnungsphase, Tagesablauf, Fragen der Eltern.",
  kindergarten_year: year,
  created_by:        sabine,
  status:            "aktiv"
)

# ── Teilnahmelisten ───────────────────────────────────────────────────────────
puts "  Teilnahmelisten …"

# Hilfsmethode: alle (Kind, Elternteil)-Paare einer Gruppe laden
def children_with_parents(group, year)
  Child.where(group: group, kindergarten_year: year)
       .includes(:parent_children => :user)
       .filter_map do |child|
         parent = child.parent_children.first&.user
         [ child, parent ] if parent
       end
end

# 1. Sommerfest-Anmeldung – allgemein, alle drei Gruppen
[ sunflowers, ladybugs, butterflies ].each do |group|
  al = AttendanceList.create!(
    title:             "Anmeldung Sommerfest",
    mode:              "general",
    group:             group,
    kindergarten_year: year,
    created_by:        sabine,
    deadline:          (sommerfest.start_date - 4.days).to_datetime.change(hour: 20),
    event_id:          sommerfest.id,
    description:       "Bitte meldet euer Kind bis spätestens #{(sommerfest.start_date - 4.days).strftime('%-d.%-m.')} an."
  )
  children_with_parents(group, year).each do |child, parent|
    AttendanceEntry.create!(list: al, child: child, user: parent)
  end
end

# 2. Zoo-Ausflug – pro-Datum (zwei mögliche Tage), nur Sonnenblumen
zoo_list = AttendanceList.create!(
  title:             "Ausflug Zoo – Datum abstimmen",
  mode:              "per_date",
  group:             sunflowers,
  kindergarten_year: year,
  created_by:        sabine,
  deadline:          (today + 4.days).to_datetime.change(hour: 18),
  event_id:          ausflug.id
)
opt_a = zoo_list.attendance_date_options.create!(date: today + 7.days)
opt_b = zoo_list.attendance_date_options.create!(date: today + 8.days)

children_with_parents(sunflowers, year).each_with_index do |(child, parent), idx|
  entry = AttendanceEntry.create!(list: zoo_list, child: child, user: parent)
  # Abwechselnd Tag A / Tag B
  chosen = idx.even? ? opt_a : opt_b
  entry.attendance_date_selections.create!(attendance_date_option: chosen)
end

# 3. Elternsprechtag – Marienkäfer, kein Deadline mehr (bereits abgelaufen)
el_list = AttendanceList.create!(
  title:             "Gesprächswunsch Elternsprechtag",
  mode:              "general",
  group:             ladybugs,
  kindergarten_year: year,
  created_by:        sabine,
  deadline:          (today - 1.day).to_datetime.change(hour: 20),
  event_id:          elternsprechtag.id,
  description:       "Bitte anmelden, wenn ihr ein persönliches Gespräch wünscht."
)
children_with_parents(ladybugs, year).first(3).each do |child, parent|
  AttendanceEntry.create!(list: el_list, child: child, user: parent)
end

# 4. Frühlingsfest (nachträglich, offene Liste für Schmetterlinge)
AttendanceList.create!(
  title:             "Frühlingsfest – Rückmeldung",
  mode:              "general",
  group:             butterflies,
  kindergarten_year: year,
  created_by:        sabine,
  event_id:          fruehlingsfest.id
)

# ── Abstimmungen ──────────────────────────────────────────────────────────────
puts "  Abstimmungen …"

# Hilfsmethode: Poll mit Optionen in einem Schritt anlegen
def create_poll(option_labels, **attrs)
  p = Poll.new(attrs)
  option_labels.each_with_index { |label, idx| p.poll_options.build(label: label, position: idx) }
  p.save!
  p
end

# 1. Elternsprechtag-Termin (Sonnenblumen, offen, Einfachauswahl)
poll_et = create_poll(
  ["Montag, #{(today + 10.days).strftime('%-d.%-m.')}",
   "Dienstag, #{(today + 11.days).strftime('%-d.%-m.')}",
   "Mittwoch, #{(today + 12.days).strftime('%-d.%-m.')}"],
  title:             "Wunschdatum Elternsprechtag",
  poll_type:         "single",
  status:            "open",
  group:             sunflowers,
  kindergarten_year: year,
  created_by:        sabine,
  deadline:          (today + 6.days).to_datetime.change(hour: 20),
  description:       "Bitte stimmt ab, welcher Termin für euch am besten passt.",
  event_id:          elternsprechtag.id
)
et_opts = poll_et.poll_options.reload.to_a
# Votes: 4 von 5 Eltern haben schon abgestimmt
User.where(email: %w[anna.gruber@example.at stefan.gruber@example.at
                     lisa.bauer@example.at eva.steiner@example.at]).each_with_index do |u, i|
  Vote.create!(poll_option: et_opts[i % et_opts.size], user: u)
end

# 2. T-Shirt-Größe Sommerfest (alle Gruppen → 3 separate Polls, je eine)
[ sunflowers, ladybugs, butterflies ].each do |group|
  p = create_poll(
    %w[98/104 110/116 122/128 134/140],
    title:             "T-Shirt-Größe für das Sommerfest",
    poll_type:         "single",
    status:            "open",
    group:             group,
    kindergarten_year: year,
    created_by:        sabine,
    deadline:          (sommerfest.start_date - 7.days).to_datetime.change(hour: 20),
    event_id:          sommerfest.id
  )
  opts = p.poll_options.reload.to_a
  children_with_parents(group, year).first(2).each_with_index do |(_, parent), i|
    Vote.create!(poll_option: opts[i % opts.size], user: parent)
  end
end

# 3. Thema nächster Elternabend – Schmetterlinge (Mehrfachauswahl, offen)
poll_ea = create_poll(
  ["Eingewöhnung – Erfahrungen & Fragen",
   "Tagesablauf & Rituale",
   "Ernährung & Jause",
   "Spielzeug von zuhause mitbringen",
   "Ausflüge & Aktivitäten"],
  title:             "Themen für den nächsten Elternabend",
  poll_type:         "multiple",
  status:            "open",
  group:             butterflies,
  kindergarten_year: year,
  created_by:        sabine,
  description:       "Ihr könnt mehrere Themen auswählen."
)
ea_opts = poll_ea.poll_options.reload.to_a
User.where(email: %w[julia.hofer@example.at nina.schuster@example.at]).each do |u|
  ea_opts.sample(2).each { |opt| Vote.create!(poll_option: opt, user: u) }
end

# 4. Geschlossene Abstimmung (Frühlingsfest-Buffet, Marienkäfer)
poll_buf = create_poll(
  ["Herzhafte Speise", "Süße Mehlspeise", "Salat oder Aufstrich", "Getränke"],
  title:             "Beitrag zum Frühlingsfest-Buffet",
  poll_type:         "single",
  status:            "closed",
  group:             ladybugs,
  kindergarten_year: year,
  created_by:        sabine,
  event_id:          fruehlingsfest.id
)
buf_opts = poll_buf.poll_options.reload.to_a
User.where(email: %w[petra.winkler@example.at markus.brunner@example.at
                     karin.fuchs@example.at christine.huber@example.at]).each_with_index do |u, i|
  Vote.create!(poll_option: buf_opts[i % buf_opts.size], user: u)
end

# ── Einkaufslisten ────────────────────────────────────────────────────────────
puts "  Einkaufslisten …"

mama_gruber_user = User.find_by(email: "anna.gruber@example.at")

# 1. Sommerfest-Einkauf (kindergartenweit, zugewiesen an Elternteil)
sl_sommer = ShoppingList.create!(
  title:             "Einkauf Sommerfest",
  event_date:        sommerfest.start_date - 1.day,
  kindergarten_year: year,
  created_by:        sabine,
  assigned_to:       mama_gruber_user,
  event_id:          sommerfest.id,
  description:       "Einkaufsliste für das Sommerfest. Anna Gruber hat sich freiwillig gemeldet."
)
[
  { name: "Limonade",              quantity: "24 Flaschen",  position: 0 },
  { name: "Mineralwasser",         quantity: "12 Flaschen",  position: 1 },
  { name: "Pappteller",            quantity: "100 Stück",    position: 2 },
  { name: "Plastikbecher",         quantity: "100 Stück",    position: 3 },
  { name: "Servietten",            quantity: "5 Packungen",  position: 4 },
  { name: "Grillanzünder",         quantity: "1 Packung",    position: 5, done: true,
    completed_by_id: sabine.id, completed_at: Time.current },
  { name: "Holzkohle",             quantity: "2 Säcke",      position: 6, done: true,
    completed_by_id: sabine.id, completed_at: Time.current },
  { name: "Würstel (vegan)",       quantity: "2 kg",         position: 7 },
  { name: "Würstel (Standard)",    quantity: "3 kg",         position: 8 },
  { name: "Weckerl",               quantity: "40 Stück",     position: 9 },
  { name: "Ketchup & Senf",        quantity: "je 2 Flaschen", position: 10 },
].each { |attrs| sl_sommer.shopping_items.create!(attrs) }

# 2. Bastelmaterialien Herbst (Sonnenblumen)
sl_bastel = ShoppingList.create!(
  title:             "Bastelmaterialien – Herbst",
  event_date:        today + 3.days,
  group:             sunflowers,
  kindergarten_year: year,
  created_by:        sabine
)
[
  { name: "Buntpapier A4",         quantity: "5 Packungen",  position: 0, done: true,
    completed_by_id: sabine.id, completed_at: Time.current },
  { name: "Klebstoff (Pritt)",     quantity: "10 Stück",     position: 1, done: true,
    completed_by_id: sabine.id, completed_at: Time.current },
  { name: "Schere (Kinderschere)", quantity: "5 Stück",      position: 2 },
  { name: "Pompons bunt",          quantity: "1 Beutel",     position: 3 },
  { name: "Wackelaugen",           quantity: "2 Packungen",  position: 4 },
  { name: "Kastanien & Zapfen",    quantity: "aus dem Garten gesammelt",  position: 5 },
].each { |attrs| sl_bastel.shopping_items.create!(attrs) }

# 3. Jause-Vorrat Marienkäfer (Gruppe)
sl_jause = ShoppingList.create!(
  title:             "Jause-Vorrat KW #{(today + 7.days).cweek}",
  event_date:        today + 7.days,
  group:             ladybugs,
  kindergarten_year: year,
  created_by:        sabine
)
[
  { name: "Vollkornbrot",           quantity: "3 Laibe",       position: 0 },
  { name: "Topfen (mager)",         quantity: "500 g",         position: 1 },
  { name: "Karotten",               quantity: "1 kg",          position: 2 },
  { name: "Äpfel",                  quantity: "2 kg",          position: 3 },
  { name: "Bananen",                quantity: "1 kg",          position: 4 },
  { name: "Hafermilch",             quantity: "4 Packungen",   position: 5, note: "laktosefrei wegen Lea Fuchs" },
].each { |attrs| sl_jause.shopping_items.create!(attrs) }

# 4. Zoo-Ausflug Getränke (Sonnenblumen)
sl_zoo = ShoppingList.create!(
  title:             "Ausflug Zoo – Getränke & Snacks",
  event_date:        ausflug.start_date,
  group:             sunflowers,
  kindergarten_year: year,
  created_by:        sabine,
  event_id:          ausflug.id
)
[
  { name: "Trinkflaschen (Ersatz)", quantity: "5 Stück",      position: 0 },
  { name: "Müsliriegel",            quantity: "20 Stück",     position: 1 },
  { name: "Sonnencreme LSF 50",     quantity: "2 Tuben",      position: 2 },
  { name: "Pflaster-Set",           quantity: "1 Set",        position: 3 },
].each { |attrs| sl_zoo.shopping_items.create!(attrs) }

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
printf "  │  Speiseplan-Tage   %-3s                        │\n", MealEntry.count
printf "  │  Speisen (Courses) %-3s                        │\n", MealCourse.count
printf "  │  Veranstaltungen   %-3s                        │\n", CalendarEvent.unscoped.count
printf "  │  Teilnahmelisten   %-3s                        │\n", AttendanceList.count
printf "  │  Abstimmungen      %-3s                        │\n", Poll.count
printf "  │  Einkaufslisten    %-3s                        │\n", ShoppingList.count
puts "  ├──────────────────────────────────────────────┤"
puts "  │  Login  sabine@mikiwa.local                   │"
puts "  │  PW     changeme12345678                     │"
puts "  └──────────────────────────────────────────────┘"
puts ""

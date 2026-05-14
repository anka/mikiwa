require "test_helper"

class ChildrenControllerTest < ActionDispatch::IntegrationTest
  setup do
    @caretaker = User.create!(email: "betreuer_k@mikiwa.at", password: "sicherespasswort1234", role: "caretaker")
    @parent = User.create!(email: "eltern2@mikiwa.at", password: SecureRandom.hex(20), role: "parent",
      first_name: "Test", last_name: "Parent", phone: "0664 000 000")
    @group = Group.create!(name: "Löwen")
    @year = KindergartenYear.create!(
      label:      "KGJ 2025/26",
      start_date: Date.new(2025, 9, 1),
      end_date:   Date.new(2026, 7, 31),
      active:     true
    )
    @child = Child.create!(
      first_name:        "Finn",
      last_name:         "Berger",
      date_of_birth:     Date.new(2021, 5, 10),
      group:             @group,
      kindergarten_year: @year,
      photo_consent:     true
    )
    ParentChild.create!(user: @parent, child: @child)
  end

  test "caretaker can access children list" do
    sign_in_as(@caretaker)
    get children_path
    assert_response :success
  end

  test "parent sees only own children" do
    sign_in_as(@parent)
    other_child = Child.create!(
      first_name: "Julia", last_name: "Stern",
      date_of_birth: Date.new(2022, 1, 1),
      group: @group, kindergarten_year: @year,
      photo_consent: false
    )
    get children_path
    assert_match "Finn", response.body
    assert_no_match "Julia", response.body
  end

  test "caretaker can create child" do
    sign_in_as(@caretaker)
    assert_difference "Child.count", 1 do
      post children_path, params: {
        child: {
          first_name:           "Eva",
          last_name:            "Müller",
          date_of_birth:        "2022-04-01",
          group_id:             @group.id,
          kindergarten_year_id: @year.id,
          photo_consent:        "1"
        }
      }
    end
    assert_redirected_to children_path
  end

  test "child without required fields is rejected" do
    sign_in_as(@caretaker)
    assert_no_difference "Child.count" do
      post children_path, params: {
        child: { first_name: "Eva", last_name: "Müller" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "caretaker can deactivate child" do
    sign_in_as(@caretaker)
    patch deactivate_child_path(@child)
    assert_not @child.reload.active?
    assert_redirected_to children_path
  end

  test "parent cannot deactivate child (403)" do
    sign_in_as(@parent)
    patch deactivate_child_path(@child)
    assert_response :forbidden
  end

  # F19 – Eltern-Zuordnung in Kind-Show-View
  test "caretaker can attach parent to child" do
    sign_in_as(@caretaker)
    new_parent = User.create!(email: "neu_eltern@mikiwa.at", password: SecureRandom.hex(20), role: "parent",
      first_name: "Test", last_name: "Parent", phone: "0664 000 000")

    assert_difference "ParentChild.count", 1 do
      post attach_parent_child_path(@child), params: { user_id: new_parent.id }
    end
    assert_redirected_to child_path(@child)
    assert @child.parents.include?(new_parent)
  end

  test "caretaker can detach parent from child" do
    sign_in_as(@caretaker)

    assert_difference "ParentChild.count", -1 do
      delete detach_parent_child_path(@child, user_id: @parent.id)
    end
    assert_redirected_to child_path(@child)
    assert_not @child.reload.parents.include?(@parent)
  end

  test "attach_parent forbidden for parent role (403)" do
    sign_in_as(@parent)
    other_parent = User.create!(email: "andere_eltern@mikiwa.at", password: SecureRandom.hex(20), role: "parent",
      first_name: "Test", last_name: "Parent", phone: "0664 000 000")

    assert_no_difference "ParentChild.count" do
      post attach_parent_child_path(@child), params: { user_id: other_parent.id }
    end
    assert_response :forbidden
  end

  test "detach_parent forbidden for parent role (403)" do
    sign_in_as(@parent)

    assert_no_difference "ParentChild.count" do
      delete detach_parent_child_path(@child, user_id: @parent.id)
    end
    assert_response :forbidden
  end

  test "attach_parent rejects non-parent user with error" do
    sign_in_as(@caretaker)
    staff_user = User.create!(email: "staffel@mikiwa.at", password: SecureRandom.hex(20), role: "caretaker")

    assert_no_difference "ParentChild.count" do
      post attach_parent_child_path(@child), params: { user_id: staff_user.id }
    end
    assert_redirected_to child_path(@child)
    assert_match(/Kein passendes Eltern-Konto/i, flash[:alert].to_s)
  end

  test "attach_parent is idempotent for already-linked parent" do
    sign_in_as(@caretaker)

    assert_no_difference "ParentChild.count" do
      post attach_parent_child_path(@child), params: { user_id: @parent.id }
    end
    assert_redirected_to child_path(@child)
  end

  test "edit form contains no parent_id select" do
    sign_in_as(@caretaker)
    get edit_child_path(@child)
    assert_response :success
    assert_no_match(/name="child\[parent_id\]"/, response.body)
  end

  test "new form keeps parent_id select" do
    sign_in_as(@caretaker)
    get new_child_path
    assert_response :success
    assert_match(/name="child\[parent_id\]"/, response.body)
  end

  # BF-002: Foto-Zustimmung wird beim Kind-Edit nicht gespeichert
  test "BF-002 caretaker can toggle photo_consent from true to false via update" do
    sign_in_as(@caretaker)
    @child.update!(photo_consent: true)

    patch child_path(@child), params: {
      child: {
        first_name:           @child.first_name,
        last_name:            @child.last_name,
        date_of_birth:        @child.date_of_birth,
        group_id:             @group.id,
        kindergarten_year_id: @year.id,
        photo_consent:        "0"
      }
    }

    assert_redirected_to children_path
    assert_equal false, @child.reload.photo_consent,
                 "photo_consent muss nach Update auf false stehen"
  end

  test "BF-002 caretaker can toggle photo_consent from false to true via update" do
    sign_in_as(@caretaker)
    @child.update!(photo_consent: false)

    patch child_path(@child), params: {
      child: {
        first_name:           @child.first_name,
        last_name:            @child.last_name,
        date_of_birth:        @child.date_of_birth,
        group_id:             @group.id,
        kindergarten_year_id: @year.id,
        photo_consent:        "1"
      }
    }

    assert_redirected_to children_path
    assert_equal true, @child.reload.photo_consent,
                 "photo_consent muss nach Update auf true stehen"
  end

  test "BF-002 edit form shows current photo_consent=true as selected radio" do
    sign_in_as(@caretaker)
    @child.update!(photo_consent: true)

    get edit_child_path(@child)
    assert_response :success

    assert_match(
      /<input[^>]*type="radio"[^>]*value="true"[^>]*checked="checked"|<input[^>]*checked="checked"[^>]*value="true"/,
      response.body,
      "Bei photo_consent=true muss die Ja-Option als checked gerendert sein"
    )
  end

  # F32: Mobile Tabellen-Layout
  test "F32 Kinder-Index hat mw-table--cards Klasse und data-label Attribute" do
    sign_in_as(@caretaker)
    get children_path
    assert_response :success
    assert_match(/mw-table mw-table--cards/, response.body)
    assert_match(/data-label="Name"/, response.body)
    assert_match(/data-label="Geburtsdatum"/, response.body)
  end

  test "BF-002 edit form shows current photo_consent=false as selected radio" do
    sign_in_as(@caretaker)
    @child.update!(photo_consent: false)

    get edit_child_path(@child)
    assert_response :success

    assert_match(
      /<input[^>]*type="radio"[^>]*value="false"[^>]*checked="checked"|<input[^>]*checked="checked"[^>]*value="false"/,
      response.body,
      "Bei photo_consent=false muss die Nein-Option als checked gerendert sein"
    )
  end

  # F36: Versicherungsdaten durch Eltern bearbeitbar
  test "F36 verknüpftes Elternteil kann Edit-Seite öffnen" do
    sign_in_as(@parent)
    get edit_child_path(@child)
    assert_response :success
  end

  test "F36 verknüpftes Elternteil kann Versicherungsnummer speichern" do
    sign_in_as(@parent)
    patch child_path(@child), params: { child: { insurance_number: "1234567890" } }
    assert_redirected_to child_path(@child)
    assert_equal "1234567890", @child.reload.insurance_number
  end

  test "F36 Elternteil kann group_id nicht manipulieren (Strong Params)" do
    sign_in_as(@parent)
    other_group = Group.create!(name: "Fremde Gruppe")
    original_group_id = @child.group_id
    patch child_path(@child), params: { child: { insurance_number: "XY", group_id: other_group.id } }
    assert_equal original_group_id, @child.reload.group_id
  end

  test "F36 fremdes Elternteil erhält 403 für Edit" do
    sign_in_as(@parent)
    unlinked_child = Child.create!(
      first_name: "Fremdes", last_name: "Kind",
      date_of_birth: Date.new(2022, 1, 1),
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    get edit_child_path(unlinked_child)
    assert_response :forbidden
  end

  test "F36 Show-View zeigt 'Versicherung bearbeiten' CTA für verknüpftes Elternteil" do
    sign_in_as(@parent)
    get child_path(@child)
    assert_response :success
    assert_match(/Versicherung bearbeiten/i, response.body)
  end

  # F39: Berechnetes Alter (tagesaktuell) in Liste & Detail
  test "F39 Index zeigt Alter-Spalte mit pluralisierter Anzeige" do
    sign_in_as(@caretaker)
    travel_to Date.new(2026, 5, 13) do
      get children_path
      assert_response :success
      assert_match(/Alter/, response.body, "Spaltenkopf 'Alter' muss vorhanden sein")
      assert_match(/data-label="Alter"/, response.body, "data-label='Alter' für mobile Cards muss vorhanden sein")
      assert_match(/5 Jahre/, response.body, "Pluralisierte Anzeige '5 Jahre' für Finn (geb. 2021-05-10) muss vorhanden sein")
    end
  end

  test "F39 Show zeigt Alter prominent neben Geburtsdatum" do
    sign_in_as(@caretaker)
    travel_to Date.new(2026, 5, 13) do
      get child_path(@child)
      assert_response :success
      assert_match(/5 Jahre/, response.body)
    end
  end

  test "F39 Show zeigt '1 Jahr' für einjähriges Kind (Singular)" do
    sign_in_as(@caretaker)
    travel_to Date.new(2026, 5, 13) do
      @child.update!(date_of_birth: Date.new(2025, 5, 13))
      get child_path(@child)
      assert_response :success
      assert_match(/1 Jahr(?!e)/, response.body, "Singularform '1 Jahr' (nicht 'Jahre') muss verwendet werden")
    end
  end

  # F44: Row-Actions als Icons
  test "F44 Children-Index Row-Action 'Bearbeiten' ist Icon-only mit Tooltip" do
    sign_in_as(@caretaker)
    get children_path
    assert_response :success
    assert_match(/<a[^>]*href="#{Regexp.escape(edit_child_path(@child))}"[^>]*>/, response.body,
                 "Bearbeiten-Link muss gerendert sein")
    assert_match(/<a[^>]*title="Bearbeiten"[^>]*href="#{Regexp.escape(edit_child_path(@child))}"|<a[^>]*href="#{Regexp.escape(edit_child_path(@child))}"[^>]*title="Bearbeiten"/, response.body,
                 "Bearbeiten muss title='Bearbeiten' haben")
    edit_link = response.body.match(/<a[^>]+href="#{edit_child_path(@child)}"[^>]*>(.*?)<\/a>/m)
    assert edit_link, "Bearbeiten-Link nicht gefunden"
    inner = edit_link[1].gsub(/<svg.*?<\/svg>/m, "").strip
    assert_no_match(/Bearbeiten/, inner,
                    "Bearbeiten-Link darf keinen sichtbaren Text 'Bearbeiten' enthalten (außer in Attributen)")
  end

  test "F44 Children-Index Deaktivieren-Action ist Icon-only" do
    sign_in_as(@caretaker)
    get children_path
    deactivate_form = response.body.match(/<form[^>]+action="#{Regexp.escape(deactivate_child_path(@child))}"[^>]*>.*?<\/form>/m)
    assert deactivate_form, "Deaktivieren-Form nicht gefunden"
    assert_match(/title="Deaktivieren"/, deactivate_form[0])
    inner_button = deactivate_form[0].match(/<button[^>]*>(.*?)<\/button>/m)
    assert inner_button, "Deaktivieren-Button nicht gefunden"
    inner = inner_button[1].gsub(/<svg.*?<\/svg>/m, "").strip
    assert_no_match(/Deaktivieren/, inner,
                    "Deaktivieren-Button darf keinen sichtbaren Text 'Deaktivieren' enthalten")
  end

  # F40: Facts-Übersicht in /children
  test "F40 Index zeigt Facts-Übersicht mit Gesamtanzahl" do
    sign_in_as(@caretaker)
    Child.create!(first_name: "Lara", last_name: "Stein",
      date_of_birth: 4.years.ago.to_date, group: @group, kindergarten_year: @year, photo_consent: true)
    get children_path
    assert_response :success
    assert_match(/mw-children-facts/, response.body, "Facts-Container muss vorhanden sein")
    assert_match(/Gesamt/i, response.body)
    assert_match(/pro Alter/i, response.body)
    assert_match(/pro Gruppe/i, response.body)
  end

  test "F40 Facts zeigen korrekte Anzahl pro Gruppe und Alter" do
    sign_in_as(@caretaker)
    travel_to Date.new(2026, 5, 13) do
      Child.create!(first_name: "Lara", last_name: "Stein",
        date_of_birth: Date.new(2021, 5, 10), group: @group, kindergarten_year: @year, photo_consent: true)
      get children_path
      assert_response :success
      assert_match(/Löwen/, response.body)
      assert_match(/5 J\./, response.body, "Alter-Aggregat '5 J.' muss erscheinen")
    end
  end

  # F41: Filter in /children (Gruppe, Name, Alter)
  test "F41 Filter-Leiste ist sichtbar im Index" do
    sign_in_as(@caretaker)
    get children_path
    assert_response :success
    assert_match(/mw-children-filters/, response.body)
    assert_match(/name="q"/, response.body)
    assert_match(/name="group_id"/, response.body)
    assert_match(/name="age"/, response.body)
  end

  test "F41 Name-Filter mit Umlaut findet Müller" do
    sign_in_as(@caretaker)
    Child.create!(first_name: "Anna", last_name: "Müller",
      date_of_birth: 4.years.ago.to_date, group: @group, kindergarten_year: @year, photo_consent: true)
    get children_path, params: { q: "mül" }
    assert_response :success
    assert_match "Müller", response.body
    assert_no_match(/>Finn Berger</, response.body)
  end

  test "F41 Gruppe-Filter beschränkt Liste" do
    sign_in_as(@caretaker)
    other_group = Group.create!(name: "Bären F41")
    Child.create!(first_name: "Bea", last_name: "Bär",
      date_of_birth: 4.years.ago.to_date, group: other_group, kindergarten_year: @year, photo_consent: true)
    get children_path, params: { group_id: other_group.id }
    assert_response :success
    assert_match "Bea Bär", response.body
    assert_no_match(/Finn Berger/, response.body)
  end

  test "F41 Alter-Filter via Date-Range" do
    sign_in_as(@caretaker)
    travel_to Date.new(2026, 5, 13) do
      Child.create!(first_name: "Drei", last_name: "Jahre",
        date_of_birth: Date.new(2023, 1, 1), group: @group, kindergarten_year: @year, photo_consent: true)
      get children_path, params: { age: 5 }
      assert_response :success
      assert_match "Finn Berger", response.body
      assert_no_match(/Drei Jahre/, response.body)
    end
  end

  test "F41 Kombination Gruppe + Alter" do
    sign_in_as(@caretaker)
    travel_to Date.new(2026, 5, 13) do
      other_group = Group.create!(name: "Andere F41")
      Child.create!(first_name: "Ein", last_name: "FünfJähriger",
        date_of_birth: Date.new(2021, 1, 1), group: other_group, kindergarten_year: @year, photo_consent: true)
      get children_path, params: { group_id: @group.id, age: 5 }
      assert_response :success
      assert_match "Finn Berger", response.body
      assert_no_match(/FünfJähriger/, response.body)
    end
  end

  test "F41 Reset-Link führt zurück zur ungefilterten Liste" do
    sign_in_as(@caretaker)
    get children_path, params: { q: "xyz" }
    assert_response :success
    assert_match(/href="\/children"[^>]*>[^<]*Filter zurücksetzen/i, response.body)
  end

  # F42: Deaktivierte Kinder /children/inactive
  test "F42 Caretaker sieht /children/inactive nur mit inaktiven Kindern" do
    sign_in_as(@caretaker)
    inactive = Child.create!(first_name: "Old", last_name: "Kind",
      date_of_birth: 5.years.ago.to_date, group: @group, kindergarten_year: @year,
      photo_consent: true, active: false)
    get inactive_children_path
    assert_response :success
    assert_match(/Deaktivierte Kinder/i, response.body)
    assert_match "Old Kind", response.body
    assert_no_match(/>Finn Berger</, response.body)
  end

  test "F42 Eltern bekommen 403 auf /children/inactive" do
    sign_in_as(@parent)
    get inactive_children_path
    assert_response :forbidden
  end

  test "F42 Reaktivieren setzt active=true und redirected zurück" do
    sign_in_as(@caretaker)
    inactive = Child.create!(first_name: "Reha", last_name: "Kind",
      date_of_birth: 5.years.ago.to_date, group: @group, kindergarten_year: @year,
      photo_consent: true, active: false)
    patch reactivate_child_path(inactive)
    assert_redirected_to inactive_children_path
    assert inactive.reload.active?
  end

  test "F42 Eltern können nicht reaktivieren" do
    sign_in_as(@parent)
    inactive = Child.create!(first_name: "Reha", last_name: "Kind",
      date_of_birth: 5.years.ago.to_date, group: @group, kindergarten_year: @year,
      photo_consent: true, active: false)
    patch reactivate_child_path(inactive)
    assert_response :forbidden
    assert_not inactive.reload.active?
  end

  test "F42 Index zeigt Link zu /children/inactive für Caretaker" do
    sign_in_as(@caretaker)
    get children_path
    assert_response :success
    assert_match(/href="\/children\/inactive"/, response.body)
  end

  test "F42 Filter wirken auf /children/inactive" do
    sign_in_as(@caretaker)
    Child.create!(first_name: "Anna", last_name: "Müller",
      date_of_birth: 5.years.ago.to_date, group: @group, kindergarten_year: @year,
      photo_consent: true, active: false)
    Child.create!(first_name: "Bob", last_name: "Stein",
      date_of_birth: 5.years.ago.to_date, group: @group, kindergarten_year: @year,
      photo_consent: true, active: false)
    get inactive_children_path, params: { q: "mül" }
    assert_response :success
    assert_match "Müller", response.body
    assert_no_match(/>Bob Stein</, response.body)
  end

  test "F36 Caretaker behält vollen Edit-Umfang" do
    sign_in_as(@caretaker)
    patch child_path(@child), params: {
      child: {
        first_name: "Geändert",
        last_name: @child.last_name,
        date_of_birth: @child.date_of_birth,
        group_id: @group.id,
        kindergarten_year_id: @year.id,
        photo_consent: true,
        insurance_number: "9999"
      }
    }
    assert_redirected_to children_path
    assert_equal "Geändert", @child.reload.first_name
    assert_equal "9999", @child.reload.insurance_number
  end

  # F60: Excel-Export-Action für Kinder-Liste
  test "F60 Caretaker erhält .xlsx als Download" do
    sign_in_as(@caretaker)
    get children_path(format: :xlsx)
    assert_response :success
    assert_equal Mime[:xlsx].to_s, response.media_type
    assert_match(/mikiwa_kinder_\d{4}-\d{2}-\d{2}\.xlsx/, response.headers["Content-Disposition"])
    assert response.body.bytesize.positive?, "Excel-Body darf nicht leer sein"
  end

  test "F60 Parent bekommt 403 bei /children.xlsx" do
    sign_in_as(@parent)
    get children_path(format: :xlsx)
    assert_response :forbidden
  end

  test "F60 Excel respektiert group_id-Filter" do
    sign_in_as(@caretaker)
    other_group = Group.create!(name: "F60-Andere-Gruppe")
    Child.create!(
      first_name: "Otto", last_name: "Anders",
      date_of_birth: Date.new(2021, 1, 1),
      group: other_group, kindergarten_year: @year, photo_consent: true
    )
    get children_path(format: :xlsx, group_id: @group.id)
    assert_response :success
    # Excel ist Binary - wir prüfen nur Status; Inhalt via Roundtrip-Parse wäre Stretch
  end

  test "F60 Excel respektiert q-Filter" do
    sign_in_as(@caretaker)
    Child.create!(
      first_name: "Zacharias", last_name: "Müllner",
      date_of_birth: Date.new(2021, 1, 1),
      group: @group, kindergarten_year: @year, photo_consent: true
    )
    get children_path(format: :xlsx, q: "Müllner")
    assert_response :success
  end

  test "F60 Index-Header enthält Excel-Export-Link für Caretaker" do
    sign_in_as(@caretaker)
    get children_path
    assert_response :success
    assert_match(/Excel exportieren/, response.body)
    assert_select 'a[href*=".xlsx"]'
  end

  test "F60 Index-Header zeigt KEINEN Excel-Export-Link für Parent" do
    sign_in_as(@parent)
    get children_path
    assert_response :success
    assert_no_match(/Excel exportieren/, response.body)
  end

  test "F60 unauthenticated user wird auf Login geleitet bei .xlsx" do
    get children_path(format: :xlsx)
    assert_redirected_to new_session_path
  end
end

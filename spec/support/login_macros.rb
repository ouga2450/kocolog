module LoginMacros
  def login_as(user)
    visit root_path

    within("header.navbar") do
      find("label[for='nav-menu-toggle']").click
      click_link I18n.t("actions.login")
    end

    fill_in "user_email", with: user.email
    fill_in "user_password", with: "password"
    click_button I18n.t("actions.login")

    within("header.navbar") do
      find("label[for='nav-menu-toggle']").click
      expect(page).to have_link(I18n.t("actions.logout"))
    end
  end
end

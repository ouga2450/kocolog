def click_nav_link(text, method: :get, **options)
  within("header.navbar") do
    find("label[for='nav-menu-toggle']").click
    if method == :delete
      page.driver.submit :delete, destroy_user_session_path, {}
    else
      find("a", text: text, visible: :visible).click
    end
  end
end

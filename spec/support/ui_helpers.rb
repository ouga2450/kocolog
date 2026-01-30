def click_nav_link(text, **options)
  within("header.navbar") do
    find("label[for='nav-menu-toggle']").click
    click_link text, **options
  end
end

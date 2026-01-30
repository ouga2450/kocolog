require "rails_helper"

RSpec.describe "Navigation", type: :system do
  let(:user) { create(:user, onboarding_completed: true, password: "password") }

  it "未ログインで保護ページにアクセスできない" do
    visit home_path
    expect(page).to have_current_path(new_user_session_path, ignore_query: true)
  end

  it "未ログインで公開ページのリンクから遷移できる" do
    visit root_path

    click_nav_link I18n.t("navigation.terms")
    expect(page).to have_current_path(terms_path, ignore_query: true)

    click_nav_link I18n.t("navigation.privacy_policy")
    expect(page).to have_current_path(privacy_path, ignore_query: true)
  end

  it "未ログインでログインリンクからログインページへ遷移できる" do
    visit root_path

    click_nav_link I18n.t("actions.login")
    expect(page).to have_current_path(new_user_session_path, ignore_query: true)
  end

  it "ログイン後にナビゲーションリンクで各ページへ遷移できる" do
    login_as(user)
    visit home_path

    click_nav_link I18n.t("navigation.habits")
    expect(page).to have_current_path(habits_path, ignore_query: true)

    click_nav_link I18n.t("navigation.calendar")
    expect(page).to have_current_path(calendars_path, ignore_query: true)

    click_nav_link I18n.t("navigation.reflection")
    expect(page).to have_current_path(reaction_path(Date.current), ignore_query: true)

    click_nav_link I18n.t("navigation.mypages")
    expect(page).to have_current_path(mypage_path, ignore_query: true)

    click_nav_link I18n.t("navigation.onboarding")
    expect(page).to have_current_path(onboarding_path, ignore_query: true)
  end

  it "初ログイン時は使い方ページに遷移する" do
    new_user = create(:user, onboarding_completed: false, password: "password")
    login_as(new_user)

    expect(page).to have_current_path(onboarding_path, ignore_query: true)
  end

  it "ログアウトリンクでログアウトできる" do
    login_as(user)
    visit home_path

    click_nav_link I18n.t("actions.logout")
    expect(page).to have_current_path(root_path, ignore_query: true)
  end
end

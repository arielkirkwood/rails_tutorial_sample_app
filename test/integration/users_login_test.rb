require 'test_helper'

class UsersLoginTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:ariel)
  end

  test "user login with invalid information" do
    get login_path
    assert_template 'sessions/new'
    post login_path, session: { email: '', password: '' }
    assert_template 'sessions/new'
    refute_empty flash
    get root_path
    assert_empty flash
  end

  test "user login with valid information followed by logout" do
    get login_path
    assert_template 'sessions/new'
    post login_path, session: { email: @user.email, password: 'password' }
    assert is_logged_in?
    assert_redirected_to @user
    follow_redirect!
    assert_template 'users/show'
    # test for presence/absence of links when logged in
    assert_select 'a[href=?]', login_path, count: 0
    assert_select 'a[href=?]', logout_path
    assert_select 'a[href=?]', user_path(@user)
    assert_select 'a[href=?]', edit_user_path(@user)
    delete logout_path
    refute is_logged_in?
    assert_redirected_to root_url
    # simulate trying to log out again
    delete logout_path
    follow_redirect!
    # test for presence/absence of links when logged out
    assert_select 'a[href=?]', login_path
    assert_select 'a[href=?]', logout_path,      count: 0
    assert_select 'a[href=?]', user_path(@user), count: 0
    assert_select 'a[href=?]', edit_user_path(@user), count: 0
  end

  test "login with remembering" do
      log_in_as(@user, remember_me: '1')
      refute_nil cookies['remember_token']
  end

  test "login without remembering" do
      log_in_as(@user, remember_me: '0')
      assert_nil cookies['remember_token']
  end
end

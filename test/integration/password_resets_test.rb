require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
    @user = users(:ariel)
  end

  test "password resets" do
    get new_password_reset_path
    assert_template 'password_resets/new'
    # invalid email
    post password_resets_path, password_reset: { email: '' }
    refute_empty flash
    assert_template 'password_resets/new'
    # valid email
    post password_resets_path, password_reset: { email: @user.email }
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    refute_empty flash
    assert_redirected_to root_url
    # password reset form
    user = assigns(:user)
    # wrong email
    get edit_password_reset_path(user.reset_token, email: '')
    assert_redirected_to root_url
    # inactive user
    user.toggle!(:activated)
    get edit_password_reset_path('wrong token', email: user.email)
    assert_redirected_to root_url
    user.toggle!(:activated)
    # right email, wrong token
    get edit_password_reset_path('wrong token', email: user.email)
    assert_redirected_to root_url
    # right email, right token
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_template 'password_resets/edit'
    assert_select 'input[name=email][type=hidden][value=?]', user.email
    # invalid password & confirmation
    patch password_reset_path(user.reset_token),
          email: user.email,
          user: { password:              'foobaz',
                  password_confirmation: 'barquux' }
    assert_select 'div#error_explanation'
    # blank password
    patch password_reset_path(user.reset_token),
          email: user.email,
          user: { password:              '    ',
                  password_confirmation: 'foobar' }
    refute_empty flash
    assert_template 'password_resets/edit'
    # valid password & confirmation
    patch password_reset_path(user.reset_token),
          email: user.email,
          user: { password:              'foobaz',
                  password_confirmation: 'foobaz' }
    assert is_logged_in?
    refute_empty flash
    assert_redirected_to user
  end

  test 'expired token' do
    get new_password_reset_path
    post password_resets_path, password_reset: { email: @user.email }

    @user = assigns(:user)
    @user.update_attribute(:reset_sent_at, 3.hours.ago)
    patch password_reset_path(@user.reset_token),
          email: @user.email,
          user: { password:              'foobar',
                  password_confirmation: 'foobar' }
    assert_response :redirect
    follow_redirect!
    assert_match(/expired/i, response.body)
  end
end

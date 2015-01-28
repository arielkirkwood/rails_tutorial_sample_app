require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  def setup
    @user = users(:ariel)
  end

  test "should get new" do
    get :new
    assert_response :success
    assert_select "title", "Sign up | Ruby on Rails Tutorial Sample App"
  end

  test "should redirect edit when not logged in" do
    get :edit, id: @user
    refute_empty flash
    assert_redirected_to login_url
  end

  test "should redirect update when not logged in" do
    patch :update, id: @user, user: { name: @user.name, email: @user.email }
    refute_empty flash
    assert_redirected_to login_url
  end
end

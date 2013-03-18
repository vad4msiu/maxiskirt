require "test_helper"

class MaxiskirtTest < Test::Unit::TestCase
  def test_should_define_factories
    factories = Maxiskirt.instance_variable_get :@factories

    assert factories["user"]
    assert factories["blog_entry"]
  end

  def test_should_attributes_for
    attr_for_user = Factory.attributes_for :user
    assert_instance_of Hash, attr_for_user
    assert_not_nil attr_for_user[:login]
    assert_not_nil attr_for_user[:email]
    assert_not_nil attr_for_user[:password]
    assert_not_nil attr_for_user[:password_confirmation]
  end

  def test_should_build_object
    user = Factory.build :user
    assert_instance_of User, user
    assert user.new_record?
  end

  def test_should_create_object
    user = Factory.create :user
    assert_instance_of User, user
    assert !user.new_record?
  end

  def test_should_create_object_with_shorthand
    user = Factory :user
    assert !user.new_record?
  end

  def test_should_assign_attributes
    user = Factory.create :user
    assert_not_nil user.login
    assert_not_nil user.email
    assert_not_nil user.password
    assert_not_nil user.password_confirmation
  end

  def test_should_chain_attributes
    user = Factory.create :user
    assert_equal user.password, user.password_confirmation
  end

  def test_should_override_attributes_on_the_fly
    user = Factory.create :user, :login => (login = "janedoe"),
      :email => (email = "janedoe@example.com"),
      :password => (password = "password"),
      :password_confirmation => (password_confirmation = "passwrod")

    assert_equal login, user.login
    assert_equal email, user.email
    assert_equal password, user.password
    assert_equal password_confirmation, user.password_confirmation

    user = Factory.create :user

    assert_not_equal login, user.login
    assert_not_equal email, user.email
    assert_not_equal password, user.password
    assert_not_equal password_confirmation, user.password_confirmation
  end

  def test_should_sequence
    user1 = Factory.create :user
    user2 = Factory.create :user
    assert_equal user1.login.sub(/\d+$/) { |n| n.to_i.succ.to_s }, user2.login
  end

  def test_should_interpolate
    user = Factory.create :user
    assert_equal "#{user.login}@example.com", user.email
  end

  def test_should_inherit
    admin = Factory.create :admin
    assert_equal 'admin', admin.login
    assert_equal 'admin@example.com', admin.email
  end

  def test_should_alias
    blog_entry = Factory.create :blog_entry
    assert_equal 'admin', blog_entry.user.login
  end

  def test_should_accept_class_as_symbol
    assert_nothing_raised do
      guest = Factory.create :guest
    end
  end

  def test_objects_should_not_corrupt_attribute_templates
    factories = Maxiskirt.instance_variable_get(:@factories)
    assert_not_same DefaultSettings, factories["guest"].__params__["settings"]
  end

  def test_factories_should_not_corrupt_attribute_templates
    alice = Factory.build :guest
    bob = Factory.build :guest

    assert_not_same DefaultSettings, alice.settings

    alice.settings["eyes"] = "brown"

    assert_equal "gray", bob.settings["eyes"]
  end

  def test_should_sequence_without_database
    assert_not_equal Factory.build(:user).login, Factory.build(:user).login
  end

  def test_should_not_dup_singletons
    assert_nothing_raised(TypeError) {
      Factory(:unbeatable)
    }
  end

  def test_should_not_dup_proc_results
    assert_same Factory(:tenant).settings, DefaultSettings
  end

  def test_should_respect_closure_arity
    assert_nothing_raised(ArgumentError) {
      Factory(:tenant, :settings => lambda { DefaultSettings })
    }
  end
end
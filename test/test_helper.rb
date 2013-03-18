require 'midiskirt'
require 'test/unit'

class Mock
  # def initialize
  #   yield self
  # end

  def save!
    @saved = true
  end

  def new_record?
    !@saved
  end
end

class User < Mock
  attr_accessor :login, :email, :password, :password_confirmation, :settings
end

class Post < Mock
  attr_accessor :user
end

class Unbeatable < Mock
  attr_accessor :locked, :state, :email, :age, :male
end

Midiskirt.define :admin, :parent => :user do |f|
  f.login "admin"
end

Midiskirt.define :user do |f|
  f.login "johndoe%d"
  f.email  "%{login}@example.com"
  f.password f.password_confirmation("foobarbaz")
end

Midiskirt.define :blog_entry, :class => Post do |f|
  f.user { Midiskirt :admin }
end

DefaultSettings = {
  "hair" => "green",
  "eyes" => "gray"
}

Midiskirt.define :guest, :class => :user do |f|
  f.login "guest"
  f.settings DefaultSettings
end

Midiskirt.define :tenant, :class => :user do |f|
  f.login "tenant"
  f.settings { DefaultSettings }
end

Midiskirt.define :unbeatable do |f|
  f.locked false
  f.state :enabled
  f.email nil
  f.age 19
  f.male true
end
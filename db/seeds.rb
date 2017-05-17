DatabaseCleaner.clean_with(:truncation)

4.times do |n|
  User.create(
    email: "foobar-#{n}@foobar.com",
    password: 'foobar',
    password_confirmation: 'foobar',
    screen_name: "foobar#{n}"
  )
end

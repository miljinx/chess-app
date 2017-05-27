DatabaseCleaner.clean_with(:truncation)

4.times do |n|
  user = User.create(
    email: "foobar-#{n}@foobar.com",
    password: 'foobar',
    password_confirmation: 'foobar',
    screen_name: "foobar#{n}"
  )
  user.games << Game.create(white_player_id: user.id)
end

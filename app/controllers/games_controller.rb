class GamesController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :show, :update]

  def index
    redirect_to new_user_session_path if !current_user
    @games = Game.available
    @all_games = Game.all
  end

  def create
    game = Game.create(white_player_id: current_user.id)
    current_user.games << game
    redirect_to game
  end

  def new
    @game = Game.new
  end

  def show
    @game = Game.find(params[:id])
    players = [@game.white_player_id, @game.black_player_id]
    redirect_to games_path unless players.include?(current_user.id)
    @player_color = (@game.white_player_id == current_user.id) ? 'white' : 'black'
  end

  def update
    @game = Game.find(params[:id])
    black_player? unless @game.black_player_id.present?
    if @game.valid?
      update_valid_game
      update_firebase(@game.id)
    else
      render :index, text: "Not Allowed. Invalid Game"
    end
  end

  def forfeit
    @game = Game.find(params[:id])
    @game.forfeit(current_user)
    flash[:alert] = 'You have forfeited the game.'
    redirect_to games_path
  end

  private

  def black_player?
    return false if @game.white_player_id == current_user.id
    @game.update_attributes(black_player_id: current_user.id)
  end

  def update_valid_game
    current_user.games << @game
    @game.populate_board if @game.pieces.empty?
    redirect_to @game
  end

  def update_firebase(game_id)
    firebase = Firebase::Client.new(ENV["databaseURL"])
    response = firebase.set(game_id, turn: 'white', created: Firebase::ServerValue::TIMESTAMP)
    response.success?
  end

  def game_params
    params.require(:game).permit(:black_player_id)
  end
end

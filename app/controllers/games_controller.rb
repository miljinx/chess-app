class GamesController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :show, :update]

  def index
    @games = Game.available
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
  end

  def update
    @game = Game.find(params[:id])
    black_player? unless @game.black_player_id.present?
    if @game.valid?
      update_valid_game
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

  def game_params
    params.require(:game).permit(:black_player_id)
  end
end

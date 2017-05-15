class PiecesController < ApplicationController
  def index
    game_id = params[:game_id]
    render json: Game.find(game_id).pieces
  end

  def update
    piece = Piece.find(params[:id])
    if current_user == piece.user
      update_firebase(piece.game.id, piece.is_black) if move_piece(piece)
    end
    render json: piece.game.pieces
  end

  private

  def piece_params
    params.require(:piece).permit(:row, :col)
  end

  def move_piece(piece)
    piece.finalize_move!(piece_params[:row].to_i, piece_params[:col].to_i)
  end

  def update_firebase(game_id, is_black)
    firebase = Firebase::Client.new(ENV["databaseURL"])
    turn = is_black ? 'White to move' : 'Black to move'
    response = firebase.set(game_id, turn: turn, created: Firebase::ServerValue::TIMESTAMP)
    response.success?
  end
end

require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17

helpers do 
  def calculate_total(cards)
    arr = cards.map{|element| element[1]}

    total = 0
    arr.each do |a|
      if a == "A"
        total += 11
      else
        total += a.to_i == 0 ? 10 : a.to_i
      end
  end

  arr.select{|element| element == "A"}.count.times do 
    break if total <= BLACKJACK_AMOUNT
    total -= 10
  end

  total 
  end

  def card_image(card)
    suit = case card[0]
      when 'H' then 'hearts'
      when 'S' then 'spades'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
    end

    value = card[1]
    if ['A', 'J', 'K', 'Q'].include?(value)
      value = case card[1]
      when 'J' then 'jack'
      when 'Q' then 'queen'
      when 'K' then 'king'
      when 'A' then 'ace'
      end
    end
    "<img src='/images/cards/#{suit}_#{value}.jpg'>"
  end

  def winner!(msg)
    @play_again = true
    @show_hit_or_stay_button = false
    @success = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
  end

  def loser!(msg)
     @play_again = true
     @show_hit_or_stay_button = false
     @error = "<strong>#{session[:player_name]} loses.</strong> #{msg}"
  end

  def tie!(msg)
    @play_again = true
    @show_hit_or_stay_button = false
    @success = "<strong>It's a tie!</strong> #{msg}"
  end
end

get '/' do 
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do 
  erb :new_player
end

post '/new_player' do 

  if params[:player_name].empty?
    @error = "Name is required."
    halt erb(:new_player)
  end

  session[:player_name] = params[:player_name]
  redirect '/game'
end

before do
  @show_hit_or_stay_button = true
end

get '/game' do 
  session[:turn] = session[:player_name]
  suits = ['H', 'S', 'D', 'C']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q','K', 'A']
  session[:deck] = suits.product(values).shuffle!
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  erb :game
end


post '/game/player/hit' do 
  session[:player_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
   winner!("session[:player_name] hit Blackjack!")
  elsif player_total > BLACKJACK_AMOUNT
   loser!("It looks like #{session[:player_name]} busted.")
  end

  erb :game
end

post '/game/player/stay' do 
  @success = "#{session[:player_name]} has chosen to Stay!"
  @show_hit_or_stay_button = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"
  @show_hit_or_stay_button = false

  dealer_total = calculate_total(session[:dealer_cards])
  if dealer_total == BLACKJACK_AMOUNT
   loser!("Dealer hit blackjack!")
  elsif dealer_total > BLACKJACK_AMOUNT
   winner!("Congratulations, dealer busted at #{dealer_total}. #{session[:player_name]} wins!")
  elsif dealer_total >= DEALER_MIN_HIT
    redirect '/game/compare'
  else
    @show_dealer_hit_button = true
  end
  erb :game
end

get '/game/compare' do
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}")
  else
    tie!("Both #{session[:player_name]} and the dealer stayed at #{dealer_total}")
  end
 
  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game_over' do
  erb :game_over
end



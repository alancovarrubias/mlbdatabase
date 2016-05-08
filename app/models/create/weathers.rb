module Create

  class Weathers

    def create(game)
      create_weathers(game)
    end

    private

      def create_weathers(game)
        if game.weathers.size == 0
          (1..3).each do |i|
            Weather.create(game: game, station: "Forecast", hour: i)
            Weather.create(game: game, station: "Actual", hour: i)
          end
        end
      end

  end

end
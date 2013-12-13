module ProtocolGenerator

  module Models

    class Sequence

      attr_accessor :name, :id, :docstring

      # todo(faucon_b): check that shots are valid (id uniqueness)
      def initialize(params = {})
        @name = params[:name]
        @id = params[:id]
        @callbacks = {}
        @callbacks[:aborted_callback] = params[:aborted_callback] if params[:aborted_callback]
        @first_shot = params[:first_shot]
        @shots = params[:shots] || {}
        @docstring = params[:docstring]
        unless shots.nil? || @shofirst_shot.nil?
          unless @shots.include?(@first_shot)
            raise ArgumentError.new("Sequence #{name} first shot is not in the declared list of shots.")
          end
        end
      end

      # Return the shots meeting a given criteria. If no criteria is given, all shots are returned.
      # @example
      #    shots(:to_server)
      # @return [Array<Models::Shot>] all the shots meeting the given criteria.
      def shots(*args)
        if args.size == 0
          return @shots.values
        elsif args.size == 1
          return @shots.values.select{|shot| shot.way == args[0]}.first
        else
          raise ArgumentError.new("Unknown criteria: #{args}")
        end
      end

      def first_shot=(first_shot)
        @first_shot = first_shot
      end

      # @example
      #    shot(:id, 3)
      #    shot(:name, "ToServer")
      #    shot(:first)
      # @return [Models::Shot] the shot meeting the given cirteria, may be nil
      def shot(*args)
        criteria = args[0]
        case criteria
        when :id
          value = args[1]
          return @shots.select{|shot_name, shot| shot.id == value}.first
        when :name
          value = args[1]
          return @shots[value]
        when :first
          @first_shot
        else
          raise ArgumentError.new("Unknown criteria: #{criteria}")
        end
      end

      def has_shot?(shot_name)
        @shots.has_key?(shot_name)
      end

      def add_shot(shot)
        if @shots.has_key?(shot.name)
          out = true
        end
        @shots[shot.name] = shot
        out
      end

      # @param [Symbol] cb a specific callback (as :aborted_callback)
      def has_callback?(cb)
        @callbacks.has_key?(cb)
      end

      # @param [Symbol] cb a callback
      # @return [String] the callback name (may be nil)
      def callback(cb)
        @callbacks[cb]
      end

      # Compute unique interger ids, starting from 0, for each shot in the sequence
      # The order of these ids is arbitrary.
      def compute_shots_id
        @shots.values.each_with_index do |shot, i|
          shot.id = i
        end
      end

    end

  end

end
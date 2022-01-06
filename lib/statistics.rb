require_relative "api_wrapper"

module Statistic
  class StatisticsByStatus
    include ApiWrapper

    def initialize(uri, status)
      @uri = uri
      @status = status
    end

    def statistics_by_status
      filter_characteres = characteres_by_status
      statistics = { total_characters: total_characters_count,
                     total_by_status: filter_characteres.size,
                     percentage_by_status: percentage_by_status,
                     species: {} }

      filter_characteres.map do | character |
        Thread.new do
          if character["status"] == @status
            statistics[:species][character["species"]] = 0 unless statistics[:species].key?(character["species"])
            statistics[:species][character["species"]] += 1
          end
        end
      end.map(&:join)
      statistics
    end

    private

    def characteres_by_status
      data=[]

      all_characters(@uri).map  do | character |
        Thread.new do
          if character["status"] == @status
            data << character
          end
        end
      end.map(&:join)

      data.flatten
    end

    def percentage_by_status
      @percentage ||= (characteres_by_status.count * 100) / total_characters_count
    end

    def total_characters_count
      @total_characters_count ||= get(@uri)["info"]["count"]
    end
  end
end
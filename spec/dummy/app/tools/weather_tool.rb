# Example tool class to demonstrate tool discovery
# This file should be placed in your main application's app/tools/ directory
# or any directory that gets loaded by your Rails application

class WeatherTool < RubyLLM::Tool
  description "Gets current weather for a location"
  param :latitude, desc: "Latitude (e.g., 52.5200)"
  param :longitude, desc: "Longitude (e.g., 13.4050)"

  def execute(latitude:, longitude:)
    url = "https://api.open-meteo.com/v1/forecast?latitude=#{latitude}&longitude=#{longitude}&wind_speed_unit=mph&temperature_unit=fahrenheit"

    response = Faraday.get(url)
    data = JSON.parse(response.body)
  rescue => e
    { error: e.message }
  end
end

require 'singleton'

class International
  include Singleton
  attr_accessor :language
  attr_accessor :supported_languages

  public
  def setup(language_code)
    @supported_languages = {
      'en' => 'sequential reading',
      'fr' => 'lecture séquentielle',
      'es' => 'lectura secuencial',
    }
    if (language_code == '')
      @language = 'en'
    elsif @supported_languages.has_key?(language_code)
      @language = language_code
    else
      puts "language #{language_code} not supported"
      exit 1
    end
  end

  def sequential_reading
    @supported_languages[@language]
  end
end


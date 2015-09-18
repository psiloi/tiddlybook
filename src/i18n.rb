# encoding: utf-8
# i18n support code
#
# copyright 2013-2015 Jean-Pierre Rivière <jn.pierre.riviere (at) gmail.com>

# This file is part of TiddlyBook.
#
#    TiddlyBook is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    TiddlyBook is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with TiddlyBook.  If not, see <http://www.gnu.org/licenses/>

require 'singleton'

class International
  include Singleton

  attr_accessor :language
  attr_accessor :supported_languages

  def initialize
    @supported_languages = {
      'en' => 'sequential reading',
      'fr' => 'lecture séquentielle',
      'es' => 'lectura secuencial',
    }
    @language = 'en'
  end

  public
  def setup(language_code)
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


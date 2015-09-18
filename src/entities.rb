# encoding: utf-8
# html entities support code
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

class Entities
  include Singleton

  def initialize
    @included_entities = {}
    @unsupported_entities = {}
    @all_supported_entities = {
      'caret' => 'x02041',  # caret insertion point
      'check' => 'x02713',  # check mark
      'cir' => 'x025CB',  # white circle
      'fnof' => '402',	# ƒ : Latin small f with hook
      'Alpha' => '913',	# Α : Greek capital letter alpha
      'Beta' => '914',	# Β : Greek capital letter beta
      'Gamma' => '915',	# Γ : Greek capital letter gamma
      'Delta' => '916',	# Δ : Greek capital letter delta
      'Epsilon' => '917',	# Ε : Greek capital letter epsilon
      'Zeta' => '918',	# Ζ : Greek capital letter zeta
      'Eta' => '919',	# Η : Greek capital letter eta
      'Theta' => '920',	# Θ : Greek capital letter theta
      'Iota' => '921',	# Ι : Greek capital letter iota
      'Kappa' => '922',	# Κ : Greek capital letter kappa
      'Lambda' => '923',	# Λ : Greek capital letter lambda
      'Mu' => '924',	# Μ : Greek capital letter mu
      'Nu' => '925',	# Ν : Greek capital letter nu
      'Xi' => '926',	# Ξ : Greek capital letter xi
      'Omicron' => '927',	# Ο : Greek capital letter omicron
      'Pi' => '928',	# Π : Greek capital letter pi
      'Rho' => '929',	# Ρ : Greek capital letter rho
      'Sigma' => '931',	# Σ : Greek capital letter sigma
      'Tau' => '932',	# Τ : Greek capital letter tau
      'Upsilon' => '933',	# Υ : Greek capital letter upsilon
      'Phi' => '934',	# Φ : Greek capital letter phi
      'Chi' => '935',	# Χ : Greek capital letter chi
      'Psi' => '936',	# Ψ : Greek capital letter psi
      'Omega' => '937',	# Ω : Greek capital letter omega
      'alpha' => '945',	# α : Greek small letter alpha
      'beta' => '946',	# β : Greek small letter beta
      'gamma' => '947',	# γ : Greek small letter gamma
      'delta' => '948',	# δ : Greek small letter delta
      'epsilon' => '949',	# ε : Greek small letter epsilon
      'zeta' => '950',	# ζ : Greek small letter zeta
      'eta' => '951',	# η : Greek small letter eta
      'theta' => '952',	# θ : Greek small letter theta
      'iota' => '953',	# ι : Greek small letter iota
      'kappa' => '954',	# κ : Greek small letter kappa
      'lambda' => '955',	# λ : Greek small letter lambda
      'mu' => '956',	# μ : Greek small letter mu
      'nu' => '957',	# ν : Greek small letter nu
      'xi' => '958',	# ξ : Greek small letter xi
      'omicron' => '959',	# ο : Greek small letter omicron
      'pi' => '960',	# π : Greek small letter pi
      'rho' => '961',	# ρ : Greek small letter rho
      'sigmaf' => '962',	# ς : Greek small letter final sigma
      'sigma' => '963',	# σ : Greek small letter sigma
      'tau' => '964',	# τ : Greek small letter tau
      'upsilon' => '965',	# υ : Greek small letter upsilon
      'phi' => '966',	# φ : Greek small letter phi
      'chi' => '967',	# χ : Greek small letter chi
      'psi' => '968',	# ψ : Greek small letter psi
      'omega' => '969',	# ω : Greek small letter omega
      'thetasym' => '977',	# ϑ : Greek small letter theta symbol
      'upsih' => '978',	# ϒ : Greek upsilon with hook symbol
      'piv' => '982',	# ϖ : pi symbol
      'bull' => '8226',	# • : bullet
      'hellip' => '8230',	# … : horizontal ellipsis
      'prime' => '8242',	# ′ : prime
      'Prime' => '8243',	# ″ : double prime
      'oline' => '8254',	# ‾ : overline
      'frasl' => '8260',	# ⁄ : fraction slash
      'weierp' => '8472',	# ℘ : script capital
      'image' => '8465',	# ℑ : blackletter capital I
      'real' => '8476',	# ℜ : blackletter capital R
      'trade' => '8482',	# ™ : trade mark sign
      'alefsym' => '8501',	# ℵ : alef symbol
      'larr' => '8592',	# ← : leftward arrow
      'uarr' => '8593',	# ↑ : upward arrow
      'rarr' => '8594',	# → : rightward arrow
      'darr' => '8595',	# ↓ : downward arrow
      'harr' => '8596',	# ↔ : left right arrow
      'crarr' => '8629',	# ↵ : downward arrow with corner leftward
      'lArr' => '8656',	# ⇐ : leftward double arrow
      'uArr' => '8657',	# ⇑ : upward double arrow
      'rArr' => '8658',	# ⇒ : rightward double arrow
      'dArr' => '8659',	# ⇓ : downward double arrow
      'hArr' => '8660',	# ⇔ : left-right double arrow
      'forall' => '8704',	# ∀ : for all
      'part' => '8706',	# ∂ : partial differential
      'exist' => '8707',	# ∃ : there exists
      'empty' => '8709',	# ∅ : empty set
      'nabla' => '8711',	# ∇ : nabla
      'isin' => '8712',	# ∈ : element of
      'notin' => '8713',	# ∉ : not an element of
      'ni' => '8715',	# ∋ : contains as member
      'prod' => '8719',	# ∏ : n-ary product
      'sum' => '8721',	# ∑ : n-ary summation
      'minus' => '8722',	# − : minus sign
      'lowast' => '8727',	# ∗ : asterisk operator
      'radic' => '8730',	# √ : square root
      'prop' => '8733',	# ∝ : proportional to
      'infin' => '8734',	# ∞ : infinity
      'ang' => '8736',	# ∠ : angle
      'and' => '8743',	# ∧ : logical and
      'or' => '8744',	# ∨ : logical or
      'cap' => '8745',	# ∩ : intersection
      'cup' => '8746',	# ∪ : union
      'int' => '8747',	# ∫ : integral
      'there4' => '8756',	# ∴ : therefore
      'sim' => '8764',	# ∼ : tilde operator
      'cong' => '8773',	# ≅ : approximately equal to
      'asymp' => '8776',	# ≈ : almost equal to
      'ne' => '8800',	# ≠ : not equal to
      'equiv' => '8801',	# ≡ : identical to
      'le' => '8804',	# ≤ : less-than or equal to
      'ge' => '8805',	# ≥ : greater-than or equal to
      'sub' => '8834',	# ⊂ : subset of
      'sup' => '8835',	# ⊃ : superset of
      'nsub' => '8836',	# ⊄ : not a subset of
      'sube' => '8838',	# ⊆ : subset of or equal to
      'supe' => '8839',	# ⊇ : superset of or equal to
      'oplus' => '8853',	# ⊕ : circled plus
      'otimes' => '8855',	# ⊗ : circled times
      'perp' => '8869',	# ⊥ : up tack
      'sdot' => '8901',	# ⋅ : dot operator
      'lceil' => '8968',	# ⌈ : left ceiling
      'rceil' => '8969',	# ⌉ : right ceiling
      'lfloor' => '8970',	# ⌊ : left floor
      'rfloor' => '8971',	# ⌋ : right floor
      'lang' => '9001',	# ⟨ : left-pointing angle bracket
      'rang' => '9002',	# ⟩ : right-pointing angle bracket
      'loz' => '9674',	# ◊ : lozenge
      'spades' => '9824',	# ♠ : black (solid) spade suit
      'clubs' => '9827',	# ♣ : black (solid) club suit
      'hearts' => '9829',	# ♥ : black (solid) heart suit
      'diams' => '9830',	# ♦ : black (solid) diamond suit
      'quot' => '34',	# " : quotation mark
      'amp' => '38',	# & : ampersand
      'lt' => '60',	# < : less-than sign
      'gt' => '62',	# > : greater-than sign
      'OElig' => '338',	# Œ : Latin capital ligature OE
      'oelig' => '339',	# œ : Latin small ligature oe
      'Scaron' => '352',	# Š : Latin capital letter S with caron
      'scaron' => '353',	# š : Latin small letter s with caron
      'Yuml' => '376',	# Ÿ : Latin capital letter Y with diaeresis
      'circ' => '710',	# ˆ : modifier letter circumflex accent
      'tilde' => '732',	# ˜ : small tilde
      'ensp' => '8194',	#   : en space
      'emsp' => '8195',	#   : em space
      'thinsp' => '8201',	#   : thin space
      '' => 'zwnj',	# ‌ : 8204; zero width non-joiner
      '' => 'zwj',	# ‍ : 8205; zero width joiner
      '' => 'lrm',	# ‎ : 8206; left-to-right mark
      '' => 'rlm',	# ‏ : 8207; right-to-left mark
      'ndash' => '8211',	# – : en dash
      'mdash' => '8212',	# — : em dash
      'lsquo' => '8216',	# ‘ : left single quotation mark
      'rsquo' => '8217',	# ’ : right single quotation mark
      'sbquo' => '8218',	# ‚ : single low-9 quotation mark
      'ldquo' => '8220',	# “ : left double quotation mark
      'rdquo' => '8221',	# ” : right double quotation mark
      'bdquo' => '8222',	# „ : double low-9 quotation mark
      'dagger' => '8224',	# † : dagger
      'Dagger' => '8225',	# ‡ : double dagger
      'permil' => '8240',	# ‰ : per mille sign
      'lsaquo' => '8249',	# ‹ : single left-pointing angle quotation
      'rsaquo' => '8250',	# › : single right-pointing angle quotation
      'euro' => '8364',	# € : euro p; &#160;  non-breaking space
      'nbsp' => '160',  #   : non-breaking space 
      'cent' => '162',	# ¢ : cent sign
      'pound' => '163',	# £ : pound sign
      'curren' => '164',	# ¤ : currency sign
      'yen' => '165',	# ¥ : yen sign
      'brvbar' => '166',	# ¦ : broken vertical bar
      'sect' => '167',	# § : section sign
      'uml' => '168',	# ¨ : diaeresis
      'copy' => '169',	# © : copyright sign
      'ordf' => '170',	# ª : feminine ordinal indicator
      'laquo' => '171',	# « : left-pointing double angle quotation mark
      'not' => '172',	# ¬ : not sign
      'shy' => '#173',	#   : soft hyphen
      'reg' => '174',	# ® : registered sign
      'macr' => '175',	# ¯ : macron
      'deg' => '176',	# ° : degree sign
      'plusmn' => '177',	# ± : plus-minus sign
      'sup2' => '178',	# ² : superscript two
      'sup3' => '179',	# ³ : superscript three
      'acute' => '180',	# ´ : acute accent
      'micro' => '181',	# µ : micro signB5
      'para' => '182',	# ¶ : pilcrow sign
      'middot' => '183',	# · : middle dot
      'cedil' => '184',	# ¸ : cedilla
      'sup1' => '185',	# ¹ : superscript one
      'ordm' => '186',	# º : masculine ordinal indicator
      'raquo' => '187',	# » : right-pointing double angle quotation mark
      'frac14' => '188',	# ¼ : vulgar fraction one- quarter
      'frac12' => '189',	# ½ : vulgar fraction one- half
      'frac34' => '190',	# ¾ : vulgar fraction three- quarters
      'iquest' => '191',	# ¿ : inverted question mark
      'Agrave' => '192',	# À : Latin capital letter A with grave
      'Aacute' => '193',	# Á : Latin capital letter A with acute
      'Acirc' => '194',	# Â : Latin capital letter A with circumflex
      'Atilde' => '195',	# Ã : Latin capital letter A with tilde
      'Auml' => '196',	# Ä : Latin capital letter A with diaeresis
      'Aring' => '197',	# Å : Latin capital letter A with ring above
      'AElig' => '198',	# Æ : Latin capital letter AE
      'Ccedil' => '199',	# Ç : Latin capital letter C with cedilla
      'Egrave' => '200',	# È : Latin capital letter E with grave
      'Eacute' => '201',	# É : Latin capital letter E with acute
      'Ecirc' => '202',	# Ê : Latin capital letter E with circumflex
      'Euml' => '203',	# Ë : Latin capital letter E with diaeresis
      'Igrave' => '204',	# Ì : Latin capital letter I with grave
      'Iacute' => '205',	# Í : Latin capital letter I with acute
      'Icirc' => '206',	# Î : Latin capital letter I with circumflex
      'Iuml' => '207',	# Ï : Latin capital letter I with diaeresis
      'eth' => '208',	# ð : Latin capital letter eth
      'Ntilde' => '209',	# Ñ : Latin capital letter N with tilde
      'Ograve' => '210',	# Ò : Latin capital letter O with grave
      'Oacute' => '211',	# Ó : Latin capital letter O with acute
      'Ocirc' => '212',	# Ô : Latin capital letter O with circumflex
      'Otilde' => '213',	# Õ : Latin capital letter O with tilde
      'Ouml' => '214',	# Ö : Latin capital letter O with diaeresis
      'times' => '215',	# × : multiplication sign
      'Oslash' => '216',	# Ø : Latin capital letter O with stroke
      'Ugrave' => '217',	# Ù : Latin capital letter U with grave
      'Uacute' => '218',	# Ú : Latin capital letter U with acute
      'Ucirc' => '219',	# Û : Latin capital letter U with circumflex
      'Uuml' => '220',	# Ü : Latin capital letter U with diaeresis
      'Yacute' => '221',	# Ý : Latin capital letter Y with acute
      'thorn' => '222',	# þ : Latin capital letter thorn
      'szlig' => '223',	# ß : Latin small letter sharp
      'agrave' => '224',	# à : Latin small letter a with grave
      'aacute' => '225',	# á : Latin small letter a with acute
      'acirc' => '226',	# â : Latin small letter a with circumflex
      'atilde' => '227',	# ã : Latin small letter a with tilde
      'auml' => '228',	# ä : Latin small letter a with diaeresis
      'aring' => '229',	# å : Latin small letter a with ring above
      'aelig' => '230',	# æ : Latin small letter ae
      'ccedil' => '231',	# ç : Latin small letter c with cedilla
      'egrave' => '232',	# è : Latin small letter e with grave
      'eacute' => '233',	# é : Latin small letter e with acute
      'ecirc' => '234',	# ê : Latin small letter e with circumflex
      'euml' => '235',	# ë : Latin small letter e with diaeresis
      'igrave' => '236',	# ì : Latin small letter i with grave
      'iacute' => '237',	# í : Latin small letter i with acute
      'icirc' => '238',	# î : Latin small letter i with circumflex
      'iuml' => '239',	# ï : Latin small letter i with diaeresis
      'eth' => '240',	# ð : Latin small letter eth
      'ntilde' => '241',	# ñ : Latin small letter n with tilde
      'ograve' => '242',	# ò : Latin small letter o with grave
      'oacute' => '243',	# ó : Latin small letter o with acute
      'ocirc' => '244',	# ô : Latin small letter o with circumflex
      'otilde' => '245',	# õ : Latin small letter o with tilde
      'ouml' => '246',	# ö : Latin small letter o with diaeresis
      'divide' => '247',	# ÷ : division sign
      'oslash' => '248',	# ø : Latin small letter o with stroke
      'ugrave' => '249',	# ù : Latin small letter u with grave
      'uacute' => '250',	# ú : Latin small letter u with acute
      'ucirc' => '251',	# û : Latin small letter u with circumflex
      'uuml' => '252',	# ü : Latin small letter u with diaeresis
      'yacute' => '253',	# ý : Latin small letter y with acute
      'thorn' => '254',	# þ : Latin small letter thorn
      'yuml' => '255',	# ÿ : Latin small letter y with diaeresisign
    }
  end

  def supported_entities
    @all_supported_entities
  end

  # include an entity
  def include(entity)
    good = @all_supported_entities.has_key?(entity)
    if good
      @included_entities[entity] = @all_supported_entities[entity]
    else
      @unsupported_entities[entity] = 1 unless @unsupported_entities.has_key?(entity)
    end
    good
  end

  def unsupported_entities
    @unsupported_entities.keys.sort
  end

  def included_entities
    @included_entities
  end

end

# encoding: utf-8

require 'pp'
require 'base64'

module RubyRTF
  class RTF2html

    def initialize()

    end

    def self.rtf?(str)
      str.include? '{\rtf1'
    end

    # File.open(ARGV[0]).read
    def parse(str)
      @prefix = ''
      @suffix = ''

      doc = RubyRTF::Parser.new.parse(str)

      str = ''#<html><body>
      doc.sections.each do |section|
        mods = section[:modifiers]

        if mods[:table]
          str << "<table width=\"100%\">"
          mods[:table].rows.each do |row|
            str << "<tr>"
            row.cells.each do |cell|
              str << "<td width=\"#{cell.width}%\">"
              cell.sections.each do |sect|
                format(str, sect)
              end
              str << "</td>"
            end
            str << "</tr>"
          end
          str << "</table>"
          next
        elsif mods[:picture]
          str << process_image(section)
          next
        end

        format(str, section)
      end

      str << ""#</body></html>
      return str
    end


    private

    def add(open, close = open)
      @prefix << "<#{open}>"
      @suffix = "</#{close}>#{@suffix}"
    end

    def format(str, section)
      @prefix = ''
      @suffix = ''

      mods = section[:modifiers]

      if mods[:paragraph]
        if section[:text].empty?
          str << "<p></p>"
        else
          add('p')
        end

      elsif mods[:tab]
        str << "&nbsp;&nbsp;&nbsp;&nbsp;"
        return
      elsif mods[:newline]
        str << "<br/>"
        return
      elsif mods[:rquote]
        str << "&rsquo;"
        return
      elsif mods[:lquote]
        str << "&lsquo;"
        return
      elsif mods[:ldblquote]
        str << "&ldquo;"
        return
      elsif mods[:rdblquote]
        str << "&rdquo;"
        return
      elsif mods[:emdash]
        str << "&mdash;"
        return
      elsif mods[:endash]
        str << "&ndash;"
        return
      elsif mods[:nbsp]
        str << "&nbsp;"
        return
      end
      return if section[:text].empty?

      add('b') if mods[:bold]
      add('i') if mods[:italic]
      add('u') if mods[:underline]
      add('sup') if mods[:superscript]
      add('sub') if mods[:subscript]
      add('del') if mods[:strikethrough]

      style = ''
      style << "font-variant: small-caps;" if mods[:smallcaps]
      style << "font-size: #{mods[:font_size]}pt;" if mods[:font_size]
      style << "font-family: \"#{mods[:font].name}\";" if mods[:font]
      if mods[:foreground_colour] && !mods[:foreground_colour].use_default?
        colour = mods[:foreground_colour]
        style << "color: rgb(#{colour.red},#{colour.green},#{colour.blue});"
      end
      if mods[:background_colour] && !mods[:background_colour].use_default?
        colour = mods[:background_colour]
        style << "background-color: rgb(#{colour.red},#{colour.green},#{colour.blue});"
      end

      add("span style='#{style}'", 'span') unless style.empty?

      str << @prefix + section[:text].force_encoding('UTF-8') + @suffix
    end

    def process_image(section)
      mods = section[:modifiers]
      mime = ''
      case mods[:picture_format]
      when 'jpeg'
        mime = 'image/jpg'
      when 'png'
        mime = 'image/png'
      when 'bmp'
        mime = 'image/bmp'
      when 'wmf'
        mime = 'image/x-wmf'
      end
      hex = section[:text].scan(/../).map(&:hex).pack('c*')
      base64 = Base64.strict_encode64(hex)
      width = 'auto'
      width = mods[:picture_width] * (mods[:picture_scale_x] || 100) / 100 if mods[:picture_width]
      height = 'auto'
      height = mods[:picture_height] * (mods[:picture_scale_y] || 100) / 100 if mods[:picture_height]
      "<img width='#{width}' height='#{height}' src=\"data:#{mime};base64,#{base64}\"/>"
    end
  end
end
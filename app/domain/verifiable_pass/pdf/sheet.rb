# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

# Renders print sheets with several passes per page from a layout described in the
# configuration (verifiable_pass.print.layouts.<name>, see verifiable_pass_defaults.yml).
#
# A layout defines the grid (page size, columns, rows, card size, origin, gaps) and one or
# more sides. Each side is printed on its own page for every sheet of cards, so a layout
# with sides front and back produces pages for duplex printing. The printed pass has no
# validity status; verification always happens through the QR code.
class VerifiablePass::Pdf::Sheet
  DATE_VALUES = %i[birthday].freeze

  attr_reader :cards

  def initialize(cards, layout: VerifiablePass.config.layout, issued_year: Date.current.year)
    @cards = cards
    @layout = layout
    @issued_year = issued_year
  end

  def render
    pdf.font(@layout[:font].presence || "LiberationSans")
    first_page = true
    cards.each_slice(per_page) do |sheet_cards|
      sides.each_with_index do |(_name, side), side_index|
        pdf.start_new_page unless first_page
        first_page = false
        draw_crop_marks if @layout[:crop_marks]
        sheet_cards.each_with_index do |card, slot|
          origin = card_origin(slot, mirrored: side_index.odd? && @layout[:duplex_mirror_columns])
          pdf.bounding_box(origin, width: card_width, height: card_height) do
            elements(side).each { |element| draw_element(element, card) }
          end
        end
      end
    end
    pdf.render
  end

  def filename
    "#{VerifiablePass.config.print_filename}.pdf"
  end

  private

  ### Elements

  def sides
    @layout[:sides].to_h
  end

  def elements(side)
    side[:elements].to_h.values.map { |element| VerifiablePass::Config.new(element) }
  end

  def draw_element(element, card)
    case element[:type].to_s
    when "background" then draw_background(element)
    when "frame" then draw_frame(element)
    when "image" then draw_image(element)
    when "text" then draw_text(element, card)
    when "line" then draw_line(element)
    when "qr" then draw_qr(element, card)
    else raise ArgumentError, "Unknown verifiable_pass element type #{element[:type].inspect}"
    end
  end

  def draw_background(element)
    pdf.fill_color color(element[:color], "FFFFFF")
    pdf.fill_rectangle [0, card_height], card_width, card_height
  end

  def draw_frame(element)
    inset = mm(element[:inset])
    pdf.stroke_color color(element[:color], "000000")
    pdf.line_width element[:width].to_f
    width = card_width - (2 * inset)
    height = card_height - (2 * inset)
    radius = mm(element[:radius])
    if radius.positive?
      pdf.stroke_rounded_rectangle [inset, card_height - inset], width, height, radius
    else
      pdf.stroke_rectangle [inset, card_height - inset], width, height
    end
  end

  def draw_image(element)
    size = mm(element[:size])
    path = VerifiablePass.config.image_path(element[:file].presence || VerifiablePass.config.logo)
    pdf.image path, at: point(element), width: size, height: size
  end

  def draw_line(element)
    pdf.stroke_color color(element[:color], text_color)
    pdf.line_width element[:line_width].to_f
    x = mm(element[:x])
    pdf.stroke_horizontal_line x, x + mm(element[:width]), at: card_height - mm(element[:y])
  end

  def draw_text(element, card)
    x = mm(element[:x])
    width = element[:width] ? mm(element[:width]) : card_width - x - mm(3)
    lines = (element[:lines] || 1).to_i
    pdf.fill_color color(element[:color], text_color)
    pdf.text_box text_value(element, card),
      at: point(element),
      width: width,
      height: element[:font_size].to_f * 1.4 * lines,
      size: element[:font_size].to_f,
      style: (element[:style].presence || "normal").to_sym,
      align: (element[:align].presence || "left").to_sym,
      overflow: :shrink_to_fit
  end

  def text_value(element, card)
    return element[:text].to_s if element[:text]

    value = if element[:attribute]
      card.person.public_send(element[:attribute])
    else
      card_value(element[:value].to_s, card)
    end
    value = I18n.l(value) if value.is_a?(Date)
    return (element[:blank] || "–").to_s if value.blank?

    element[:format] ? format(element[:format].to_s, value: value) : value.to_s
  end

  def card_value(key, card)
    case key
    when "issued_year" then @issued_year
    when "name", "list_name", "member_number", "organization_name", "pass_name"
      card.public_send(key)
    else raise ArgumentError, "Unknown verifiable_pass text value #{key.inspect}"
    end
  end

  # QR code as vector graphic so it stays sharp when printed. Adjacent dark modules of a
  # row are drawn as one slightly overlapping rectangle to avoid hairline gaps.
  def draw_qr(element, card)
    modules = card.qr_code.qrcode.modules
    module_size = mm(element[:size]) / modules.size
    overlap = module_size * 0.04
    left, top = point(element)

    pdf.fill_color "000000"
    modules.each_with_index do |row, row_index|
      dark_runs(row).each do |start, length|
        pdf.fill_rectangle [left + (start * module_size), top - (row_index * module_size)],
          (length * module_size) + overlap, module_size + overlap
      end
    end
  end

  # [[start column, length], ...] of the dark sections of a row
  def dark_runs(row)
    row.each_with_index.chunk_while { |(a, _), (b, _)| a == b }
      .select { |run| run.first.first }
      .map { |run| [run.first.last, run.size] }
  end

  ### Grid

  def pdf
    @pdf ||= Export::Pdf::Document.new(page_size: @layout[:page_size] || "A4", margin: 0).pdf
  end

  def mm(value)
    value.to_f.mm
  end

  def color(value, default)
    value.presence&.to_s&.delete_prefix("#") || default
  end

  def text_color
    color(@layout[:text_color], "222222")
  end

  def point(element)
    [mm(element[:x]), card_height - mm(element[:y])]
  end

  def per_page = columns * rows

  def columns = @layout[:columns].to_i

  def rows = @layout[:rows].to_i

  def card_width = mm(@layout[:card_width])

  def card_height = mm(@layout[:card_height])

  def gap_x = mm(@layout[:gap_x])

  def gap_y = mm(@layout[:gap_y])

  def grid_width = (columns * card_width) + ((columns - 1) * gap_x)

  def grid_height = (rows * card_height) + ((rows - 1) * gap_y)

  def grid_left
    @layout[:origin_x] ? mm(@layout[:origin_x]) : (pdf.bounds.width - grid_width) / 2
  end

  def grid_top
    offset = @layout[:origin_y] ? mm(@layout[:origin_y]) : (pdf.bounds.height - grid_height) / 2
    pdf.bounds.height - offset
  end

  def card_origin(slot, mirrored: false)
    column = slot % columns
    row = slot / columns
    column = columns - 1 - column if mirrored
    [grid_left + (column * (card_width + gap_x)), grid_top - (row * (card_height + gap_y))]
  end

  def draw_crop_marks
    length = mm(@layout[:crop_mark_length] || 4)
    offset = mm(@layout[:crop_mark_offset] || 1.5)
    left = grid_left
    top = grid_top
    right = left + grid_width
    bottom = top - grid_height

    pdf.stroke_color "000000"
    pdf.line_width 0.25
    (0...columns).flat_map { |c| x = left + (c * (card_width + gap_x)); [x, x + card_width] }
      .uniq.each do |x|
        pdf.stroke_line [x, top + offset], [x, top + offset + length]
        pdf.stroke_line [x, bottom - offset], [x, bottom - offset - length]
      end
    (0...rows).flat_map { |r| y = top - (r * (card_height + gap_y)); [y, y - card_height] }
      .uniq.each do |y|
        pdf.stroke_line [left - offset, y], [left - offset - length, y]
        pdf.stroke_line [right + offset, y], [right + offset + length, y]
      end
  end
end

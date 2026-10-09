# frozen_string_literal: true

#  Copyright (c) 2026, Stefan Hofmann. This file is part of
#  hitobito_verifiable_pass and licensed under the Affero General Public License version 3
#  or later. See the LICENSE file at the top-level directory.

require "spec_helper"

describe VerifiablePass::Pdf::Sheet do
  let(:person) { people(:top_leader) }
  let(:card) { VerifiablePass::Card.new(create_pass(person)) }

  def text_of(pdf)
    PDF::Inspector::Text.analyze(pdf).strings.join(" ")
  end

  def page_count(pdf)
    PDF::Inspector::Page.analyze(pdf).pages.size
  end

  def layout(hash)
    VerifiablePass::Config.new(hash)
  end

  let(:duplex_layout) do
    layout(
      page_size: "A4", columns: 2, rows: 2, card_width: 85, card_height: 55,
      origin_x: 20, origin_y: 11, duplex_mirror_columns: true,
      sides: {
        front: {elements: {title: {type: "text", text: "MEMBERSHIP", x: 0, y: 30, width: 85,
                                   font_size: 12, align: "center"}}},
        back: {elements: {
          background: {type: "background", color: "FAF8EB"},
          frame: {type: "frame", inset: 2.5, radius: 4, width: 1.4, color: "0F3C1E"},
          line: {type: "line", x: 10, y: 10, width: 60, line_width: 0.5},
          name: {type: "text", value: "list_name", x: 7, y: 20, font_size: 9},
          email: {type: "text", attribute: "email", x: 7, y: 26, font_size: 9},
          birthday: {type: "text", attribute: "birthday", x: 7, y: 32, font_size: 9},
          issued: {type: "text", value: "issued_year", format: "Issued %{value}", x: 7, y: 40,
                   font_size: 6},
          qr: {type: "qr", x: 60, y: 16, size: 20}
        }}
      }
    )
  end

  it "renders the default layout" do
    pdf = described_class.new([card]).render

    expect(page_count(pdf)).to eq 1
    expect(text_of(pdf)).to include person.full_name
  end

  it "puts ten cards on a page in the default layout" do
    pdf = described_class.new([card] * 11).render

    expect(page_count(pdf)).to eq 2
  end

  it "prints one page per side for every sheet" do
    pdf = described_class.new([card] * 5, layout: duplex_layout).render

    # 5 cards, 4 per sheet: 2 sheets with front and back
    expect(page_count(pdf)).to eq 4
  end

  it "renders static texts, values, attributes and formats" do
    person.update_column(:birthday, Date.new(1980, 5, 17))

    text = text_of(described_class.new([card], layout: duplex_layout, issued_year: 2031).render)

    expect(text).to include "MEMBERSHIP"
    expect(text).to include "Leader, Top"
    expect(text).to include person.email
    expect(text).to include "17.05.1980"
    expect(text).to include "Issued 2031"
  end

  it "shows the blank placeholder for empty values" do
    person.update_column(:birthday, nil)

    text = text_of(described_class.new([card], layout: duplex_layout).render)

    expect(text).to include "–"
  end

  it "translates texts with i18n keys" do
    custom = layout(
      columns: 1, rows: 1, card_width: 85, card_height: 55,
      sides: {card: {elements: {issued: {type: "text", value: "issued_year", x: 5, y: 5,
                                         font_size: 8, lines: 2,
                                         i18n: "verifiable_pass.print.issued"}}}}
    )

    text = text_of(described_class.new([card], layout: custom, issued_year: 2031).render)

    expect(text).to include I18n.t("verifiable_pass.print.issued", value: 2031).split(" ").first
  end

  it "raises for unknown element types" do
    broken = layout(columns: 1, rows: 1, card_width: 85, card_height: 55,
      sides: {card: {elements: {x: {type: "hologram"}}}})

    expect { described_class.new([card], layout: broken).render }
      .to raise_error(ArgumentError, /hologram/)
  end

  it "raises for unknown text values" do
    broken = layout(columns: 1, rows: 1, card_width: 85, card_height: 55,
      sides: {card: {elements: {x: {type: "text", value: "password", x: 1, y: 1, font_size: 8}}}})

    expect { described_class.new([card], layout: broken).render }
      .to raise_error(ArgumentError, /password/)
  end

  it "renders an empty sheet without cards" do
    expect { described_class.new([]).render }.not_to raise_error
  end
end

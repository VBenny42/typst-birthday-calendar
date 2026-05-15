
#let calendar(year: "", body) = {
  set document(title: str(year) + " calendar")

  // Got from https://www.officeholidays.com/ics-all/trinidad-and-tobago
  // Converted from .ics to .csv using https://www.projectwizards.net/en/support/ics2csv-converter
  // Will figure out own way to do this in the future, but for now this is good enough
  // Converted from tsv to csv with `tr -s "\t" ":" < trinidad-and-tobago-colon.tsv > trinidad-and-tobago-colon.csv`
  let raw_public_holidays = csv(
    "trinidad-and-tobago-colon.csv",
    delimiter: ":",
    row-type: dictionary,
  )
  let public_holidays = raw_public_holidays
    .map(event => {
      let parts = event.at("Given planned earliest start").split(".")
      let date = datetime(
        day: int(parts.at(0)),
        month: int(parts.at(1)),
        year: int(parts.at(2)),
      )
      (
        date: date,
        name: event.at("Title"),
      )
    })
    // filter events to only include those in the specified year
    .filter(event => event.date.year() == year)

  let raw_birthdays = csv(
    "birthdays.csv",
    row-type: dictionary,
  )
  let birthdays = raw_birthdays.map(entry => {
    let parts = entry.at("Birthday").split(".")
    let date = datetime(
      day: int(parts.at(0)),
      month: int(parts.at(1)),
      year: if parts.len() > 2 { int(parts.at(2)) } else { 0 },
    )
    (
      date: date,
      name: entry.at("Person")
        + if parts.len() > 2 { " (" + str(year - date.year()) + ")" },
      image: entry.at("Image"),
    )
  })

  let ordinal = n => {
    let suffix = if calc.rem(n, 100) in (11, 12, 13) { "th" } else if (
      calc.rem(n, 10) == 1
    ) { "st" } else if calc.rem(n, 10) == 2 { "nd" } else if (
      calc.rem(n, 10) == 3
    ) { "rd" } else { "th" }
    str(n) + suffix
  }

  let header = (arr, title /* color */) => {
    if arr.len() > 0 [
      // #set text(color)
      #linebreak()
      #text(size: 12pt)[#title]
      #text(size: 10pt)[
        #(
          arr
            .map(event => {
              [#event.name (#ordinal(event.date.day()))]
            })
            .join(", ")
        )
      ]
    ]
  }

  pagebreak(weak: true)

  for month in range(1, 13) [

    #let birthdays_this_month = (
      birthdays
        .filter(event => (
          event.date.month() == month
        ))
        .sorted(key: event => event.date.day())
    )

    #if birthdays_this_month.len() > 0 {
      let bounds = 2in
      let images_with_paths = birthdays_this_month.filter(event => (
        event.image != ""
      ))
      let count = images_with_paths.len()

      // divide page into a grid based on count
      let cols = calc.max(1, calc.ceil(calc.sqrt(count)))
      let rows = calc.max(1, calc.ceil(count / cols))
      let cell_width = 500 / cols // in pts
      let cell_height = 400 / rows
      let header_offset = 0.5in

      for (i, event) in images_with_paths.enumerate() [
        #let col = calc.rem(i, cols)
        #let row = i / cols
        #let seed = event.name.len() + i
        // add small random offset within cell so it doesn't look too rigid
        #let jitter_x = (
          calc.rem(seed * 17, calc.max(1, int(cell_width) - 144)) * 1pt
        )
        #let jitter_y = (
          calc.rem(seed * 13, calc.max(1, int(cell_height) - 144)) * 1pt
        )
        #place(
          top + left,
          dx: col * cell_width * 1pt + jitter_x,
          dy: header_offset + row * cell_height * 1pt + jitter_y,
          box(
            width: bounds,
            height: bounds,
            clip: true,
            radius: 50%,
            image(event.image, width: bounds, height: bounds, fit: "cover"),
          ),
        )
      ]
    }



    // Header with public holidays and birthdays for the month
    #header(
      public_holidays.filter(event => event.date.month() == month),
      "Public holidays:",
      // aqua,
    )
    #header(
      birthdays_this_month,
      "Birthdays:",
      // green,
    )


    #pagebreak()
    #let month_date = datetime(
      year: year,
      month: month,
      day: 1,
    )

    #let monthly_days = ()

    #for day in range(0, 31) [
      #let month_accumulator = (month_date + duration(days: day))
      #if month_accumulator.month() != month {
        break
      }
      #monthly_days.push(month_accumulator)
    ]

    #align(left)[
      #heading(level: 1)[
        #text(size: 27pt)[#month_date.display("[month repr:long]") #year
        ]
      ]
    ]

    #let first_sunday = {
      int(monthly_days.first().display("[weekday repr:sunday]"))
    }

    #let row_count = calc.floor((first_sunday + monthly_days.len()) / 7)

    #show table.cell.where(y: 0): strong
    #pad(
      y: 5%,
      table(
        columns: (1fr,) * 7,
        rows: (0.4fr,) + row_count * (1fr,),
        inset: 0.8em,
        table.header(
          table.cell(align: center)[Sunday],
          table.cell(align: center)[Monday],
          table.cell(align: center)[Tuesday],
          table.cell(align: center)[Wednesday],
          table.cell(align: center)[Thursday],
          table.cell(align: center)[Friday],
          table.cell(align: center)[Saturday],
        ),
        ..range(1, first_sunday).map(empty_day => []),
        ..monthly_days.map(day => {
          let public_holiday_events = public_holidays.filter(event => (
            event.date.month() == day.month() and event.date.day() == day.day()
          ))
          let is_holiday = public_holiday_events.len() > 0

          let birthday_events = birthdays
            .filter(event => (
              event.date.month() == day.month()
                and event.date.day() == day.day()
            ))
            .map(event => (name: emph(event.name)))

          let is_birthday = birthday_events.len() > 0

          let fill = none
          if is_birthday and is_holiday {
            fill = purple.lighten(60%)
          } else if is_birthday {
            fill = green.lighten(60%)
          } else if is_holiday {
            fill = aqua.lighten(60%)
          }

          let day_events = birthday_events + public_holiday_events

          table.cell(
            fill: fill,
            // stroke: if (is_birthday or is_holiday) {
            //   (dash: "dashed")
            // } else { (thickness: 1.5pt) },
            [
              #day.display("[day padding:none]")
              #if day_events.len() > 0 [
                #linebreak()
                #text(size: 7pt)[
                  #day_events.map(event => event.name).join("\n")
                ]
              ]
            ],
          )
        }),
        stroke: (x, y) => {
          if y == 0 { return none }
          let cell_index = (y - 1) * 7 + x
          let day_index = cell_index - (first_sunday - 1)
          if day_index < 0 or day_index >= monthly_days.len() { return none }
          (thickness: 1.5pt)
        },
      ),
    )

    #pagebreak(weak: true)
  ]
}

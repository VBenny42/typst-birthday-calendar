#let calendar(year: "", normalise_to_five_weeks: false, body) = {
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

    let placement = if entry.at("Placement") != "" {
      let parts = entry.at("Placement").trim("(").trim(")").split(".")
      let x = int(parts.at(0))
      let y = int(parts.at(1))
      (x: x, y: y)
    } else { (x: 0, y: 0) }

    (
      date: date,
      name: entry.at("Person"),
      // + if parts.len() > 2 { " (" + str(year - date.year()) + ")" },
      image: entry.at("Image"),
      placement: placement,
      size: if entry.at("Size") != "" { float(entry.at("Size")) } else { 1.0 },
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

  let header = (arr, title) => {
    if arr.len() > 0 [
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

  // Just anything but content
  let blank_cell = 1

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

      let header_offset = 0in
      if (
        public_holidays.filter(event => event.date.month() == month).len() > 0
      ) {
        header_offset += 0.0in
      }
      if (birthdays_this_month.len() > 0) {
        header_offset += 0.0in
      }

      for (i, event) in images_with_paths.enumerate() [
        #let x = event.placement.x
        #let y = event.placement.y
        #let bounds = event.size * bounds

        #let radius = 50%

        #if event.size > 1.0 {
          let difference = event.size - 1.0
          radius = radius - difference * 20%
        }

        #place(
          horizon + center,
          dx: x * 0.1in,
          dy: header_offset + y * 0.1in,
          box(
            width: bounds,
            height: bounds,
            clip: true,
            radius: radius,
            image(event.image, width: bounds, height: bounds, fit: "cover"),
          ),
        )
      ]
    }

    // Header with public holidays and birthdays for the month
    #header(
      public_holidays.filter(event => event.date.month() == month),
      "Public holidays:",
    )
    #header(
      birthdays_this_month,
      "Birthdays:",
    )


    #pagebreak()
    #let month_date = datetime(
      year: year,
      month: month,
      day: 1,
    )

    #let monthly_days = ()

    #for day in range(0, 31) {
      let month_accumulator = (month_date + duration(days: day))
      if month_accumulator.month() != month {
        break
      }
      monthly_days.push(month_accumulator)
    }

    #align(left)[
      #heading(level: 1)[
        #month_date.display("[month repr:long]") #year
      ]
    ]

    #let first_day_as_week_int = int(
      monthly_days.first().display("[weekday repr:sunday]"),
    )


    #let saturdays = ()
    #for (index, day) in monthly_days.enumerate() {
      if int(day.display("[weekday repr:sunday]")) == 7 {
        saturdays.push(index)
      }
    }


    #let total_rows = saturdays.len()
    #let start_of_last_week = saturdays.last() + 1
    #if monthly_days.len() - start_of_last_week > 0 {
      total_rows += 1

      if total_rows > 5 and normalise_to_five_weeks {
        total_rows -= 1

        let last_week = ()

        while monthly_days.last().day() != start_of_last_week {
          last_week.push(monthly_days.pop())
        }

        monthly_days = (
          last_week.rev()
            // Pad with blanks
            + (
              (first_day_as_week_int - (last_week.len() + 1)) * (blank_cell,)
            )
            + monthly_days
        )
      } else {
        monthly_days = first_day_as_week_int * (blank_cell,) + monthly_days
      }
    }

    #let cell_inset = 0.8em
    #let event_inset = 0.2em

    #show table.cell.where(y: 0): strong
    #show table.cell.where(y: 0): set align(center)
    #pad(
      y: 6%,
      table(
        columns: (1fr,) * 7,
        rows: (0.4fr,) + total_rows * (1fr,),
        inset: cell_inset,
        table.header(
          [Sunday],
          [Monday],
          [Tuesday],
          [Wednesday],
          [Thursday],
          [Friday],
          [Saturday],
        ),
        ..monthly_days.map(day => {
          if type(day) == type(blank_cell) {
            return
          }

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

          let inset = if day_events.len() > 0 {
            event_inset
          } else { cell_inset }

          table.cell(
            fill: fill,
            inset: inset,
            [
              #if day_events.len() > 0 {
                box(
                  width: 100%,
                  height: 100%,
                  inset: cell_inset - event_inset,
                  stroke: (
                    paint: fill.darken(35%),
                    thickness: 1pt,
                    dash: "dotted",
                  ),
                )[
                  #day.display("[day padding:none]")
                  #linebreak()
                  #text(size: 9pt)[
                    #day_events.map(event => event.name).join("\n")
                  ]
                ]
              } else {
                day.display("[day padding:none]")
              }
            ],
          )
        }),
        stroke: (x, y) => {
          if y == 0 { return none }
          let cell_index = (y - 1) * 7 + x
          if (
            type(monthly_days.at(cell_index, default: blank_cell))
              == type(blank_cell)
          ) {
            return none
          }
          (thickness: 1.5pt)
        },
      ),
    )

    #pagebreak(weak: true)
  ]
}

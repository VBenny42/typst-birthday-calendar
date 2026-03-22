#import "birthday_images.typ": birthday_image_filepaths

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
  // repr(public_holidays)

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

    // Header with public holidays and birthdays for the month
    #header(
      public_holidays.filter(event => event.date.month() == month),
      "Public holidays:",
      // aqua,
    )
    #header(
      birthdays.filter(event => event.date.month() == month),
      "Birthdays:",
      // green,
    )

    #let birthdays_this_month = birthdays.filter(event => (
      event.date.month() == month
    ))

    // #if birthdays_this_month.len() > 0 {
    //   let bounds = 3in
    //   align(center + horizon)[
    //     #for event in birthdays_this_month [
    //       #let image_filepath = birthday_image_filepaths.at(
    //         event.name.split(" (").first(),
    //         default: none,
    //       )
    //       #if image_filepath != none {
    //         box(
    //           width: bounds,
    //           height: bounds,
    //           clip: true,
    //           radius: 50%,
    //           image(
    //             image_filepath,
    //             width: bounds,
    //             height: bounds,
    //             fit: "cover",
    //           ),
    //         )
    //       }
    //     ]
    //   ]
    // }

    #if birthdays_this_month.len() > 0 {
      for (i, event) in birthdays_this_month.enumerate() [
        #let image_filepath = if event.image != "" { event.image } else { none }
        #if image_filepath != none {
          let bounds = 2in
          let seed = event.name.len() * (i + 1)

          // let max_x = page.width - page.margin-left - page.margin-right - 1.5in
          // let max_y = page.height - page.margin-top - page.margin-bottom - 1.5in

          let x = calc.rem(seed * 73, 700) * 1pt
          let y = calc.rem(seed * 37, 300) * 1pt
          place(
            top + left,
            dx: x,
            dy: y,
            box(
              width: bounds,
              height: bounds,
              clip: true,
              radius: 50%,
              image(
                image_filepath,
                width: bounds,
                height: bounds,
                fit: "cover",
              ),
            ),
          )
        }
      ]
    }

    // #if birthdays_this_month.len() > 0 {
    //   let images_to_show = birthdays_this_month.filter(event => (
    //     birthday_image_filepaths.at(
    //       event.name.split(" (").first(),
    //       default: none,
    //     )
    //       != none
    //   ))
    //   if images_to_show.len() > 0 [
    //     #align(center + horizon)[
    //       #grid(
    //         columns: images_to_show.len(),
    //         column-gutter: 1fr,
    //         ..images_to_show.map(event => {
    //           let image_filepath = birthday_image_filepaths.at(
    //             event.name.split(" (").first(),
    //             default: none,
    //           )
    //           box(
    //             width: 1.5in,
    //             height: 1.5in,
    //             clip: true,
    //             radius: 50%,
    //             image(
    //               image_filepath,
    //               width: 1.5in,
    //               height: 1.5in,
    //               fit: "cover",
    //             ),
    //           )
    //         })
    //       )
    //     ]
    //   ]
    // }

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
          [Sunday],
          [Monday],
          [Tuesday],
          [Wednesday],
          [Thursday],
          [Friday],
          [Saturday],
        ),
        ..range(1, first_sunday).map(empty_day => []),
        ..monthly_days.map(day => {
          let public_holiday_events = public_holidays.filter(event => (
            event.date.month() == day.month() and event.date.day() == day.day()
          ))
          let is_holiday = public_holiday_events.len() > 0

          let birthday_events = birthdays.filter(event => (
            event.date.month() == day.month() and event.date.day() == day.day()
          ))
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
            // fill: if is_holiday { aqua.lighten(60%) } else { none },
            fill: fill,
            [
              #day.display("[day padding:none]")
              #if day_events.len() > 0 [
                #linebreak()
                // #text(size: 7pt)[#day_events.first().name]
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

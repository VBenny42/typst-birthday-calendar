#import "calendar.typ": calendar

#set page(
  "us-letter",
  flipped: true,
  margin: (
    top: 0.5in,
    bottom: 0.5in,
    left: 0.5in,
    right: 0.5in,
  ),
)
#set text(size: 14pt, font: "Helvetica")
// #set text(size: 14pt, font: "Noto Sans Javanese")

#show heading.where(level: 1): set text(size: 27pt)

#show: calendar.with(
  year: datetime.today().year(),
  normalise_to_five_weeks: true,
)

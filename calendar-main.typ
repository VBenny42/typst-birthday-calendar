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

#show: calendar.with(
  year: datetime.today().year(),
)

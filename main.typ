#import "calendar.typ": calendar

#set page(
  "us-letter",
  flipped: true,
  margin: 8%,
)
#set text(size: 14pt, font: "Helvetica")
// #set text(size: 14pt, font: "Noto Sans Javanese")

#show: calendar.with(
  year: datetime.today().year(),
)

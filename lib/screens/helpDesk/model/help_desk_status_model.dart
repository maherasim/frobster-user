enum HelpDeskStatus {
  all,
  open,
  closed,
}

class HelpDeskStatusModel {
  HelpDeskStatus status;
  String name;
  String apiStatus;

  HelpDeskStatusModel({
    this.status = HelpDeskStatus.all,
    this.name = "",
    this.apiStatus = "",
  });
}

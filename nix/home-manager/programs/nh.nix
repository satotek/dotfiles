{ lib, ... }:
{
  # programs.nh.clean の dates "weekly" は月曜 0:00 になる。日曜 12:15 の system 側
  # Store GC より前に世代を整理しておき、その GC で同じ週のうちに回収させる。
  launchd.agents.nh-clean.config.StartCalendarInterval = lib.mkForce [
    {
      Weekday = 7;
      Hour = 12;
      Minute = 0;
    }
  ];
}

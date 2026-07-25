import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/get_my_post_job_list_response.dart';

extension RemoteWorkLevelLocalization on RemoteWorkLevel {
  String get localizedLabel {
    switch (this) {
      case RemoteWorkLevel.onsite0:
        return language.onsiteFullPresenceLabel;
      case RemoteWorkLevel.remote25:
        return '25% ${language.remoteWorkShareSuffix}';
      case RemoteWorkLevel.remote50:
        return '50% ${language.remoteWorkShareSuffix}';
      case RemoteWorkLevel.remote75:
        return '75% ${language.remoteWorkShareSuffix}';
      case RemoteWorkLevel.remote100:
        return '100% ${language.remoteWorkShareSuffix}';
    }
  }
}

extension CareerLevelLocalization on CareerLevel {
  String get localizedLabel {
    switch (this) {
      case CareerLevel.notSpecified:
        return language.lblCareerNotSpecified;
      case CareerLevel.entryLevel:
        return language.lblCareerEntryLevel;
      case CareerLevel.intermediateLevel:
        return language.lblCareerIntermediateLevel;
      case CareerLevel.experienced:
        return language.lblCareerExperienced;
      case CareerLevel.professional:
        return language.lblCareerProfessional;
      case CareerLevel.middleManagement:
        return language.lblCareerMiddleManagement;
      case CareerLevel.executiveManagement:
        return language.lblCareerExecutiveManagement;
      case CareerLevel.seniorManagement:
        return language.lblCareerSeniorManagement;
      case CareerLevel.director:
        return language.lblCareerDirector;
      case CareerLevel.technician:
        return language.lblCareerTechnician;
      case CareerLevel.leader:
        return language.lblCareerLeader;
      case CareerLevel.manager:
        return language.lblCareerManager;
    }
  }
}

extension TravelRequirementLocalization on TravelRequirement {
  String get localizedLabel {
    switch (this) {
      case TravelRequirement.no:
        return language.lblNo;
      case TravelRequirement.yes:
        return language.lblYes;
    }
  }
}

extension EducationLevelLocalization on EducationLevel {
  String get localizedLabel {
    switch (this) {
      case EducationLevel.notSpecified:
        return language.lblEduNotSpecified;
      case EducationLevel.anyGraduate:
        return language.lblEduAnyGraduate;
      case EducationLevel.apprenticeshipDegree:
        return language.lblEduApprenticeship;
      case EducationLevel.traineeshipDegree:
        return language.lblEduTraineeship;
      case EducationLevel.secondaryDegree:
        return language.lblEduSecondaryDegree;
      case EducationLevel.undergraduateDiploma:
        return language.lblEduUndergraduate;
      case EducationLevel.highSchoolGraduate:
        return language.lblEduHighSchool;
      case EducationLevel.associateDegree:
        return language.lblEduAssociate;
      case EducationLevel.collegeDegree:
        return language.lblEduCollege;
      case EducationLevel.universityDegree:
        return language.lblEduUniversity;
      case EducationLevel.bachelorsDegree:
        return language.lblEduBachelors;
      case EducationLevel.mastersDegree:
        return language.lblEduMasters;
      case EducationLevel.doctorateDegree:
        return language.lblEduDoctorate;
      case EducationLevel.professionalDegree:
        return language.lblEduProfessional;
      case EducationLevel.notSpecified2:
        return language.lblEduNotSpecified2;
      case EducationLevel.anyGraduate2:
        return language.lblEduAnyGraduate2;
      case EducationLevel.apprenticeshipDegree2:
        return language.lblEduApprenticeship2;
      case EducationLevel.traineeshipDegree2:
        return language.lblEduTraineeship2;
      case EducationLevel.secondaryDegree2:
        return language.lblEduSecondaryDegree2;
      case EducationLevel.undergraduateDiploma2:
        return language.lblEduUndergraduate2;
    }
  }
}

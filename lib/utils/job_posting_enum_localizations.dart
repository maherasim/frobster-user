import 'package:booking_system_flutter/main.dart';
import 'package:booking_system_flutter/model/get_my_post_job_list_response.dart';

extension RemoteWorkLevelLocalization on RemoteWorkLevel {
  String get localizedLabel {
    switch (this) {
      case RemoteWorkLevel.onsite0:
        return language.onsiteFullPresenceLabel;
      case RemoteWorkLevel.remote25:
        return '25 % ${language.remoteWorkShareSuffix}';
      case RemoteWorkLevel.remote50:
        return '50 % ${language.remoteWorkShareSuffix}';
      case RemoteWorkLevel.remote75:
        return '75 % ${language.remoteWorkShareSuffix}';
      case RemoteWorkLevel.remote100:
        return '100 % ${language.remoteWorkShareSuffix}';
    }
  }
}

extension CareerLevelLocalization on CareerLevel {
  String get localizedLabel {
    switch (this) {
      case CareerLevel.notSpecified:
        return language.careerNotSpecified;
      case CareerLevel.entryLevel:
        return language.careerEntryLevel;
      case CareerLevel.intermediateLevel:
        return language.careerIntermediateLevel;
      case CareerLevel.experienced:
        return language.careerExperienced;
      case CareerLevel.professional:
        return language.careerProfessional;
      case CareerLevel.middleManagement:
        return language.careerMiddleManagement;
      case CareerLevel.executiveManagement:
        return language.careerExecutiveManagement;
      case CareerLevel.seniorManagement:
        return language.careerSeniorManagement;
      case CareerLevel.director:
        return language.careerDirector;
      case CareerLevel.technician:
        return language.careerTechnician;
      case CareerLevel.leader:
        return language.careerLeader;
      case CareerLevel.manager:
        return language.careerManager;
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
        return language.eduNotSpecified;
      case EducationLevel.anyGraduate:
        return language.eduAnyGraduate;
      case EducationLevel.apprenticeshipDegree:
        return language.eduApprenticeshipDegree;
      case EducationLevel.traineeshipDegree:
        return language.eduTraineeshipDegree;
      case EducationLevel.secondaryDegree:
        return language.eduSecondaryDegree;
      case EducationLevel.undergraduateDiploma:
        return language.eduUndergraduateDiploma;
      case EducationLevel.highSchoolGraduate:
        return language.eduHighSchoolGraduate;
      case EducationLevel.associateDegree:
        return language.eduAssociateDegree;
      case EducationLevel.collegeDegree:
        return language.eduCollegeDegree;
      case EducationLevel.universityDegree:
        return language.eduUniversityDegree;
      case EducationLevel.bachelorsDegree:
        return language.eduBachelorsDegree;
      case EducationLevel.mastersDegree:
        return language.eduMastersDegree;
      case EducationLevel.doctorateDegree:
        return language.eduDoctorateDegree;
      case EducationLevel.professionalDegree:
        return language.eduProfessionalDegree;
      case EducationLevel.notSpecified2:
        return language.lblEduBachelor;
      case EducationLevel.anyGraduate2:
        return language.lblEduMaster;
      case EducationLevel.apprenticeshipDegree2:
        return language.lblEduStaatsexamen;
      case EducationLevel.traineeshipDegree2:
        return language.lblEduPromotion;
      case EducationLevel.secondaryDegree2:
        return language.lblEduHabilitation;
      case EducationLevel.undergraduateDiploma2:
        return language.lblEduProfessur;
    }
  }
}

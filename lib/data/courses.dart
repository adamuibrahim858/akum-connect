class Programme {
  final String programmeName;
  final String abbreviation;
  final double duration;

  const Programme({
    required this.programmeName,
    required this.abbreviation,
    required this.duration,
  });
}

class Department {
  final String departmentName;
  final List<Programme> programmes;

  const Department({required this.departmentName, required this.programmes});
}

class Faculty {
  final String facultyName;
  final List<Department> departments;

  const Faculty({required this.facultyName, required this.departments});
}

const List<Faculty> allFaculties = [
  Faculty(
    facultyName: "Faculty of Allied Health Sciences",
    departments: [
      Department(
        departmentName: "Complementary and Alternative Medicine",
        programmes: [
          Programme(
            programmeName: "Complementary and Alternative Medicine",
            abbreviation: "CAM",
            duration: 5.0,
          ),
        ],
      ),
      Department(
        departmentName: "Environmental Health Science",
        programmes: [
          Programme(
            programmeName: "Environmental Health Science",
            abbreviation: "EHS",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Medical Laboratory Science",
        programmes: [
          Programme(
            programmeName: "Medical Laboratory Science",
            abbreviation: "MLS",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Nursing Science",
        programmes: [
          Programme(
            programmeName: "Nursing Science",
            abbreviation: "NCS",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Public Health",
        programmes: [
          Programme(
            programmeName: "Public Health",
            abbreviation: "PHS",
            duration: 4.0,
          ),
        ],
      ),
    ],
  ),
  Faculty(
    facultyName: "Faculty of Computing",
    departments: [
      Department(
        departmentName: "Computer Science",
        programmes: [
          Programme(
            programmeName: "Computer Science",
            abbreviation: "CSC",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Cyber Security",
        programmes: [
          Programme(
            programmeName: "Cyber Security",
            abbreviation: "CYB",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Data Science",
        programmes: [
          Programme(
            programmeName: "Data Science",
            abbreviation: "DTS",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Software Engineering",
        programmes: [
          Programme(
            programmeName: "Software Engineering",
            abbreviation: "SEN",
            duration: 4.0,
          ),
        ],
      ),
    ],
  ),
  Faculty(
    facultyName: "Faculty of Education",
    departments: [
      Department(
        departmentName: "Arts and Social Science Education",
        programmes: [
          Programme(
            programmeName: "Education and Arabic Language",
            abbreviation: "ARB",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Education and Christian Religious Studies",
            abbreviation: "CRS",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Education and Economics",
            abbreviation: "ECO",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Education and English Language",
            abbreviation: "ENG",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Education and Hausa",
            abbreviation: "HAU",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Education and Islamic Religious Studies",
            abbreviation: "ISS",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Education and Political Science",
            abbreviation: "POL",
            duration: 4.0,
          ),
          Programme(
            programmeName: "History and International Relations",
            abbreviation: "HIS",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Social Studies and Civic Education",
            abbreviation: "ESS",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Sustainable Development Studies",
            abbreviation: "SDS",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Education",
        programmes: [
          Programme(
            programmeName: "Adult and Continuing Education",
            abbreviation: "ACE",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Educational Management",
            abbreviation: "EDM",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Guidance and Cognitive Science",
            abbreviation: "GCS",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Library Information Science",
            abbreviation: "LIS",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Primary Education",
            abbreviation: "PED",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Special Needs Education",
            abbreviation: "ESP",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Sciences Education",
        programmes: [
          Programme(
            programmeName: "Biology Education",
            abbreviation: "BIO",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Computer Science Education",
            abbreviation: "ECSC",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Education and Chemistry",
            abbreviation: "CHE",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Education and Geography",
            abbreviation: "GEO",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Education and Mathematics",
            abbreviation: "MAT",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Education and Physics",
            abbreviation: "PHY",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Human Kinetics and Health Education",
            abbreviation: "KHE",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Integrated Science",
            abbreviation: "ISC",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Statistics Education",
            abbreviation: "STE",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Technical and Vocational Education",
        programmes: [
          Programme(
            programmeName: "Agricultural Extension",
            abbreviation: "AGE",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Agricultural Science Education",
            abbreviation: "EAS",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Animal Production",
            abbreviation: "ANP",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Automobile Technology Education",
            abbreviation: "ATE",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Building Technology Education",
            abbreviation: "BTE",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Business Education",
            abbreviation: "BUS",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Creative Arts",
            abbreviation: "CAT",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Education Accounting",
            abbreviation: "ACC",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Electrical/Electronics Technology Education",
            abbreviation: "ETE",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Entrepreneurship Education",
            abbreviation: "ENE",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Home Economics Education",
            abbreviation: "HME",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Metalwork Technology Education",
            abbreviation: "MTE",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Soil Science",
            abbreviation: "SOS",
            duration: 4.0,
          ),
          Programme(
            programmeName: "Woodwork Technology Education",
            abbreviation: "WTE",
            duration: 4.0,
          ),
        ],
      ),
    ],
  ),
  Faculty(
    facultyName: "Faculty of Engineering and Innovation",
    departments: [
      Department(
        departmentName: "Agricultural and Bio-system Engineering",
        programmes: [
          Programme(
            programmeName: "Agricultural and Bio-system Engineering",
            abbreviation: "ABE",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Biomedical Engineering",
        programmes: [
          Programme(
            programmeName: "Biomedical Engineering",
            abbreviation: "BME",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Computer Engineering",
        programmes: [
          Programme(
            programmeName: "Computer Engineering",
            abbreviation: "CPE",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Mechatronics Engineering",
        programmes: [
          Programme(
            programmeName: "Mechatronics Engineering",
            abbreviation: "MCE",
            duration: 4.0,
          ),
        ],
      ),
    ],
  ),
  Faculty(
    facultyName: "Faculty of Environmental Sciences",
    departments: [
      Department(
        departmentName: "Clothing and Textile Design",
        programmes: [
          Programme(
            programmeName: "Clothing and Textile Design",
            abbreviation: "CLT",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Environmental Management",
        programmes: [
          Programme(
            programmeName: "Environmental Management",
            abbreviation: "EVM",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Estate Management",
        programmes: [
          Programme(
            programmeName: "Estate Management",
            abbreviation: "ESM",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Quantity Surveying",
        programmes: [
          Programme(
            programmeName: "Quantity Surveying",
            abbreviation: "QTS",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Urban and Regional Planning",
        programmes: [
          Programme(
            programmeName: "Urban and Regional Planning",
            abbreviation: "URP",
            duration: 4.0,
          ),
        ],
      ),
    ],
  ),
  Faculty(
    facultyName: "Faculty of Management Sciences",
    departments: [
      Department(
        departmentName: "Business Information Technology",
        programmes: [
          Programme(
            programmeName: "Business Information Technology",
            abbreviation: "BIT",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Employment and Human Resources Management",
        programmes: [
          Programme(
            programmeName: "Employment and Human Resources Management",
            abbreviation: "EHR",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Entrepreneurship",
        programmes: [
          Programme(
            programmeName: "Entrepreneurship",
            abbreviation: "ENT",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Procurement Logistics and Supply Chain Management",
        programmes: [
          Programme(
            programmeName: "Procurement Logistics and Supply Chain Management",
            abbreviation: "LSM",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Securities and Investment Management",
        programmes: [
          Programme(
            programmeName: "Securities and Investment Management",
            abbreviation: "SIM",
            duration: 4.0,
          ),
        ],
      ),
    ],
  ),
  Faculty(
    facultyName: "Faculty of Sustainable Agriculture and Biotechnology",
    departments: [
      Department(
        departmentName: "Agribusiness",
        programmes: [
          Programme(
            programmeName: "Agribusiness",
            abbreviation: "AGB",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Biotechnology",
        programmes: [
          Programme(
            programmeName: "Biotechnology",
            abbreviation: "BTG",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Family and Consumer Sciences",
        programmes: [
          Programme(
            programmeName: "Family and Consumer Sciences",
            abbreviation: "FCS",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Food Science and Technology",
        programmes: [
          Programme(
            programmeName: "Food Science and Technology",
            abbreviation: "FST",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Forest Resources and Wildlife Management",
        programmes: [
          Programme(
            programmeName: "Forest Resources and Wildlife Management",
            abbreviation: "FWM",
            duration: 4.0,
          ),
        ],
      ),
      Department(
        departmentName: "Horticulture and Landscape Management",
        programmes: [
          Programme(
            programmeName: "Horticulture and Landscape Management",
            abbreviation: "HLM",
            duration: 4.0,
          ),
        ],
      ),
    ],
  ),
];

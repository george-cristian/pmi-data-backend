DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM schema_migrations WHERE version = 1) THEN

        -- Create custom types
        CREATE TYPE report_type_enum AS ENUM ('manufacturing', 'services');

        -- Main reports table
        CREATE TABLE pmi_reports (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            report_year INTEGER NOT NULL CHECK (report_year >= 2000 AND report_year <= 2100),
            report_month INTEGER NOT NULL CHECK (report_month BETWEEN 1 AND 12),
            report_type report_type_enum NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            
            UNIQUE(report_year, report_month, report_type)
        );

        -- Scores table
        CREATE TABLE pmi_scores (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            report_id UUID NOT NULL REFERENCES pmi_reports(id) ON DELETE CASCADE,
            section VARCHAR(50) NOT NULL,
            industry VARCHAR(100) NOT NULL,
            score INTEGER NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            
            UNIQUE(report_id, section, industry),
            CONSTRAINT valid_scores CHECK (score BETWEEN -50 AND 50)
        );

        -- Indexes for performance
        CREATE INDEX idx_pmi_reports_year ON pmi_reports(report_year);
        CREATE INDEX idx_pmi_reports_month ON pmi_reports(report_month);
        CREATE INDEX idx_pmi_reports_type ON pmi_reports(report_type);
        CREATE INDEX idx_pmi_reports_year_month_type ON pmi_reports(report_year, report_month, report_type);

        CREATE INDEX idx_pmi_scores_report_id ON pmi_scores(report_id);
        CREATE INDEX idx_pmi_scores_section ON pmi_scores(section);
        CREATE INDEX idx_pmi_scores_industry ON pmi_scores(industry);
        CREATE INDEX idx_pmi_scores_score ON pmi_scores(score);
        CREATE INDEX idx_pmi_scores_composite ON pmi_scores(report_id, section, industry);

        -- Insert migration record
        INSERT INTO schema_migrations (version, applied_at, description)
        VALUES (1, NOW(), 'Initial schema with reports and scores tables');
    END IF;
END $$;

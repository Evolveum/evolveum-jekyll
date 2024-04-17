# (C) 2024 Evolveum
#
# Evolveum page Plugin for Jekyll
#
# Plugin to compile information about midpoint features, and generates feature pages.
# The plugin is also processing compliance controls, generating details pages for them.

require 'yaml'

module Evolveum

    class FeatureGenerator < Generator
        priority :lowest

        FEATURES_URL = '/midpoint/features/current/'
        ISO27001_URL = '/midpoint/compliance/iso27001/'

        def self.collect(site)
            generator = Evolveum::FeatureGenerator.new()
            generator.init(site)
            generator.collectPages()
            generator.processCompliance()
#            puts(YAML.dump(generator.findFeature('information-classification')))
        end

        def init(site)
            @site = site
            @features = site.data['midpoint-features']
            @iso27001 = site.data['compliance-iso27001']
        end

        def collectPages()
            @site.pages.each do |page|
                collectPage(page)
            end
        end

        def collectPage(page)

            feature = page.data['midpoint-feature']
#                puts("  [F] #{page.url}: #{feature}")
            if feature != nil
                if feature.kind_of?(Array)
                    feature.each { |f| collectPageFeature(page, f) }
                else
                    collectPageFeature(page, feature)
                end
            end

            compliance = page.data['compliance']
            if compliance != nil
                collectPageCompliance(page, compliance)
            end
        end

        def collectPageFeature(page, feature)
            if !feature or feature == 'true'
                return
            end
            version = page.data['midpointBranchDisplayName']
#            puts("  [F] #{page.url}: #{feature} v#{version}")
            f = findFeature(feature)
            if !f
                Jekyll.logger.warn("Referencing unknown feature #{feature} in #{page.url}")
                return
            end
            type = page.data['doc-type']
            if !type
                Jekyll.logger.warn("No doc-type in #{page.url}, assuming config")
                type = 'config'
            end
            if !version
                version = 'global'
            end
#            puts("  [FF] #{f}")
            if !f.key?('doc')
                f['doc'] = {}
            end
            if !f['doc'].key?(version)
                f['doc'][version] = {}
            end
            if !f['doc'][version].key?(type)
                f['doc'][version][type] = []
            end
            f['doc'][version][type] << page
        end

        def collectPageCompliance(page, compliance)
            iso = compliance['iso27001']
            if iso != nil
                collectPageComplianceIso27001(page, iso)
            end
        end

        def collectPageComplianceIso27001(page, complianceIso)
            complianceIso.each { |id,val| collectPageComplianceIso27001Control(page,id,val) }
        end

        def collectPageComplianceIso27001Control(page, controlId, info)
            version = page.data['midpointBranchDisplayName']
#            puts("  [C] #{page.url}: ISO27001 #{controlId} v#{version}")
            control = findIso27001Control(controlId)
            if !control
                Jekyll.logger.warn("Referencing unknown ISO27001 control #{controlId} in #{page.url}")
                return
            end
            if !version
                version = 'global'
            end
#            puts("  [FF] #{f}")
            if !control.key?('doc')
                control['doc'] = {}
            end
            if !control['doc'].key?(version)
                control['doc'][version] = []
            end
            i = info.clone
            i['page'] = page
            control['doc'][version] << i
        end

        def processCompliance()
            @features.each { |feature| processComplianceFeature(feature) }
        end

        def processComplianceFeature(feature)
            @iso27001.each do |control|
                if control.key?('features') and control['features'].include?(feature['id'])
                    if !feature.key?('compliance')
                        feature['compliance'] = {}
                    end
                    if !feature['compliance'].key?('iso27001')
                        feature['compliance']['iso27001'] = []
                    end
                    feature['compliance']['iso27001'] << control
                end
            end
        end

        def findFeature(feature)
            @features.find { |f| f['id'] == feature }
        end

        def findIso27001Control(controlId)
            @iso27001.find { |c| c['id'] == controlId }
        end

        def generate(site)
#            puts "=========[ EVOLVEUM feature ]============== generate"
            init(site)
            @nav = site.data['nav']
            @navFeatures = @nav.resolvePath(FEATURES_URL)
            @navIso27001 = @nav.resolvePath(ISO27001_URL)
            @isoDisplayOrder = 100

            @features.each do |feature|
                @site.pages << generateFeaturePage(feature)
            end

            @iso27001.each do |control|
                @site.pages << generateIso27001Page(control)
            end
        end

        def generateFeaturePage(feature)
            slug = feature['id']
#            puts("  [F] GEN #{slug}")
            # WARNING: Magic follows.
            # We create new "virtual" page using PageWithoutAFile class.
            # This page has no source file, we will explicitly read the content from feature.html "template"
            url = FEATURES_URL + slug
            page = Jekyll::PageWithoutAFile.new(@site, __dir__, url, "index.html")
            # The "stub.html" template is in the gem, in the same dir as this source code (hence __dir__)
            page.content = File.read(File.join(__dir__, 'feature.html'))
            page.data["layout"] = "feature"
            page.data['title'] = feature['title']
            page.data['midpoint-feature'] = feature['id']
            page.data['doc-type'] = 'feature'
            page.data['feature'] = feature

            nav = Evolveum::Nav.new(slug)
            nav.page = page
            nav.url = url
            nav.title = feature['title']
            @navFeatures.add(nav)

            feature['url'] = url

            page
        end

        def generateIso27001Page(control)
            slug = control['id']
#            puts("  [FC] GEN #{slug}")
            # WARNING: Magic follows.
            # We create new "virtual" page using PageWithoutAFile class.
            # This page has no source file, we will explicitly read the content from feature.html "template"
            url = ISO27001_URL + slug
            page = Jekyll::PageWithoutAFile.new(@site, __dir__, url, "index.html")
            # The "stub.html" template is in the gem, in the same dir as this source code (hence __dir__)
            page.content = File.read(File.join(__dir__, 'iso27001.html'))
            page.data["layout"] = "iso27001"
            page.data['title'] = 'ISO/IEC 27001 Control ' + control['id'] + ': ' + control['title']
            page.data['nav-title'] = control['id']
            page.data['display-order'] = @isoDisplayOrder.to_s
            @isoDisplayOrder = @isoDisplayOrder + 1
            page.data['control'] = control
            page.data['doc-type'] = 'compliance'

            nav = Evolveum::Nav.new(slug)
            nav.page = page
            nav.url = url
            nav.title = control['id']
            @navIso27001.add(nav)

            control['url'] = url

            page
        end

        def to_s()
            return "FeatureGenerator()"
        end
    end

end

Jekyll::Hooks.register :site, :post_read do |site|
#    puts "=========[ EVOLVEUM feature ]============== post_read"
    Evolveum::FeatureGenerator.collect(site)
end

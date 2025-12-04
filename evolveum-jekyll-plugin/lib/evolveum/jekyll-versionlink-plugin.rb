# (C) 2021 Evolveum
#
# Evolveum page Plugin for Jekyll
#
# TODO
#


module Evolveum

    class VersionlinksTag < Liquid::Tag

        def initialize(tag_name, text, tokens)
          super
          @config = YAML.load(text)
        end

        def render(context)
            @versions = context['site']['data']['midpoint-versions']

            @s = StringIO.new
            head()
            data()
            foot()
            return @s.string
        end

        def head()
            @s << "<table class=\"tableblock frame-all grid-all fit-content\">\n"
            @s << "  <colgroup>\n"
            @s << "    <col>\n"
            @config['columns'].each{ @s << "    <col>\n"}
            @s << "  </colgroup>\n"
            @s << "  <thead>\n"
            @s << "    <tr>\n"
            headRow("Version")
            @config['columns'].each{ |col| headRow(col['heading'])}
            @s << "    </tr>\n"
            @s << "  </thead>\n"
        end

        def headRow(heading)
            @s << "      <th class=\"tableblock halign-left valign-top\">#{heading}</th>\n"
        end

        def data()
            @s << "  <tbody>\n"
            if @config['development']
                develEntry = @versions.select { |v| v['status'] == 'development' && ( v['docsReleaseBranch'] == 'master' || v['docsReleaseBranch'] == 'main') }[0]
                if develEntry.nil?
                    Jekyll.logger.warn "No development version found for versionlinks tag in #{context['page']['url']}"
                else
                    versionEntry = develEntry.clone()
                    versionEntry['git-tag'] = "master"
                    versionEntry['maven-version'] = versionEntry['version'] + "-SNAPSHOT"
                    versionEntry['download-tag'] = "latest"
                    if @config['development'].is_a?(Hash) && @config['development']['columns']
                        columnConfig = @config['development']['columns']
                    else
                        columnConfig = @config['columns']
                    end
                    versionRow(versionEntry, columnConfig)
                end
            end
            @versions
                .reverse
                .select { |v| v['status'] != 'development' && v['status'] != 'planned' }
                .each { |v| versionRow(expandVersionEntry(v), @config['columns']) }
            @s << "  </tbody>\n"
        end

        def expandVersionEntry(orig)
            expanded = orig.clone()
            expanded['git-tag'] = "v" + expanded['version']
            expanded['maven-version'] = expanded['version']
            expanded['download-tag'] = expanded['version']
            return expanded
        end

        def versionRow(versionEntry, columnConfig)
            if @versionTooOld
                return
            end
            if @config['since'] == versionEntry['version']
                # this will be applied to next entry and all following
                @versionTooOld = true
            end
            @s << "    <tr>\n"
            @s << "      <th class=\"tableblock halign-left valign-top\"><p class=\"tableblock\">"
            @s << versionEntry['maven-version']
            significant = false
            if versionEntry['status'] == 'development'
                @s << "<br>(development)"
            else
                if @latestStable == nil
                    @s << "<br>(latest stable"
                    @latestStable = versionEntry
                    significant = true
                    if versionEntry['support'] == 'lts'
                        @s << ", LTS"
                        @latestLts = versionEntry
                    end
                    @s << ")"
                else
                    if versionEntry['support'] == 'lts' && @latestLts == nil
                        @s << "<br>(latest LTS)"
                        @latestLts = versionEntry
                        significant = true
                    end
                end
            end
            @s << "</p></th>\n"

            dataColumns(versionEntry, columnConfig)

            @s << "    </tr>\n"
        end

        def dataColumns(versionEntry, columnConfig)
            columnConfig.each{ |col| dataColumn(versionEntry, col)}
        end

        def dataColumn(versionEntry, configEntry)
            @s << "      <td class=\"tableblock halign-left valign-top\"><p class=\"tableblock\">"
            if configEntry['linkUrlPattern']
                @s << createLink(configEntry, versionEntry)
            elsif configEntry['links']
                @s << configEntry['links'].map { |linkEntry| createLink(linkEntry, versionEntry) }.join(", ")
            end
            @s << "</p></td>\n"
        end

        def createLink(linkEntry, versionEntry)
            if linkEntry['linkUrlPattern']
                href = expandPattern(linkEntry['linkUrlPattern'], versionEntry)
            else
                href = linkEntry['linkUrl']
            end
            if linkEntry['linkTextPattern']
                text = expandPattern(linkEntry['linkTextPattern'], versionEntry)
            else
                text = linkEntry['linkText']
            end
            "<a href=\"#{href}\">#{text}</a>"
        end

        def expandPattern(pattern, versionEntry)
            pattern.gsub(/\$\{([\w\d\-\_]+)\}/) { versionEntry[$1] }
        end

        def foot()
            @s << "</table>\n"
        end

    end


end

# Registering custom Liquid tags with Jekyll

Liquid::Template.register_tag('versionlinks', Evolveum::VersionlinksTag)

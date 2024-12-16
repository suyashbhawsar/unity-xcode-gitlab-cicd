#!/usr/bin/env ruby
require 'xcodeproj'

class XcodeProjectModifier
  TEAM_ID = 'Y47Z7TCT8Z'
  
  def initialize(project_path)
    @project_path = project_path
    @project = Xcodeproj::Project.open(project_path)
    @unity_iphone_target = find_target('Unity-iPhone')
    @unity_framework_target = find_target('UnityFramework')
    
    validate_targets
  end

  def modify_project
    move_resources
    set_native_call_proxy_public
    configure_signing
    update_agora_frameworks
    save_project
  end

  private

  def find_target(name)
    @project.targets.find { |t| t.name == name }
  end

  def validate_targets
    unless @unity_iphone_target && @unity_framework_target
      raise "Error: Could not find required targets"
    end
  end

  def move_resources
    resources_phase = @unity_iphone_target.resources_build_phase
    framework_resources_phase = @unity_framework_target.resources_build_phase || 
                              @unity_framework_target.new_resources_build_phase

    resources_to_move = []
    resources_phase.files.each do |build_file|
      if build_file.file_ref && ['Data', 'Images.xcassets', 'LaunchScreen-iPhone.storyboard', 
          'LaunchScreen-iPhonePortrait.png', 'LaunchScreen-iPhoneLandscape.png', 
          'LaunchScreen-iPad.storyboard', 'LaunchScreen-iPad.png'].include?(build_file.file_ref.path)
        resources_to_move << build_file.file_ref
      end
    end

    resources_to_move.each do |file_ref|
      build_file = resources_phase.files.find { |bf| bf.file_ref == file_ref }
      resources_phase.remove_build_file(build_file) if build_file
      framework_resources_phase.add_file_reference(file_ref)
    end

    puts "Successfully moved resources from Unity-iPhone to UnityFramework"
  end

  def set_native_call_proxy_public
    headers_build_phase = @unity_framework_target.headers_build_phase
    native_call_proxy = @project.files.find { |file| file.path == 'Libraries/Plugins/iOS/NativeCallProxy.h' }

    if native_call_proxy
      existing_build_file = headers_build_phase.files.find { |bf| bf.file_ref == native_call_proxy }
      headers_build_phase.remove_build_file(existing_build_file) if existing_build_file

      build_file = headers_build_phase.add_file_reference(native_call_proxy)
      build_file.settings = { 'ATTRIBUTES' => ['Public'] }

      puts "Successfully set NativeCallProxy.h as Public"
    else
      puts "Warning: Could not find NativeCallProxy.h file"
    end
  end

  def configure_signing
    [@unity_iphone_target, @unity_framework_target].each do |target|
      target.build_configurations.each do |config|
        config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
        config.build_settings['DEVELOPMENT_TEAM'] = TEAM_ID
        config.build_settings['CODE_SIGN_IDENTITY'] = 'Apple Development'
        config.build_settings['CODE_SIGN_IDENTITY[sdk=iphoneos*]'] = 'Apple Development'
        
        config.build_settings.delete('PROVISIONING_PROFILE')
        config.build_settings.delete('PROVISIONING_PROFILE_SPECIFIER')
      end
    end

    puts "Successfully enabled automatic signing for both targets with team ID: #{TEAM_ID}"
  end

  def update_agora_frameworks
    agora_frameworks = [
      'AgoraAiEchoCancellationExtension.framework',
      'AgoraAiNoiseSuppressionExtension.framework',
      'AgoraAudioBeautyExtension.framework',
      'AgoraCore.framework',
      'AgoraDrmLoaderExtension.framework',
      'Agoraffmpeg.framework',
      'Agorafdkaac.framework',
      'AgoraRtcKit.framework',
      'AgoraRtcWrapper.framework',
      'AgoraSoundTouch.framework',
      'AgoraSpatialAudioExtension.framework'
    ]

    embed_frameworks_build_phase = find_or_create_embed_frameworks_phase
    process_agora_frameworks(agora_frameworks, embed_frameworks_build_phase)

    puts "Successfully updated Agora frameworks embed settings"
  end

  def find_or_create_embed_frameworks_phase
    embed_phase = @unity_framework_target.build_phases.find { |bp| 
      bp.is_a?(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase) && 
      bp.name == 'Embed Frameworks' 
    }
    
    unless embed_phase
      embed_phase = @unity_framework_target.new_copy_files_build_phase('Embed Frameworks')
      embed_phase.symbol_dst_subfolder_spec = :frameworks
    end

    embed_phase
  end

  def process_agora_frameworks(frameworks, embed_phase)
    frameworks.each do |framework_name|
      framework_ref = @project.files.find { |f| 
        f.path.end_with?(framework_name) &&
        f.path.include?('Agora-RTC-Plugin')
      }

      if framework_ref
        remove_existing_framework_references(framework_ref)
        add_framework_references(framework_ref, embed_phase)
      else
        puts "Warning: Could not find framework: #{framework_name}"
      end
    end
  end

  def remove_existing_framework_references(framework_ref)
    @unity_framework_target.build_phases.each do |phase|
      phase.files.each do |build_file|
        phase.remove_build_file(build_file) if build_file.file_ref == framework_ref
      end
    end
  end

  def add_framework_references(framework_ref, embed_phase)
    frameworks_build_phase = @unity_framework_target.frameworks_build_phase
    frameworks_build_phase.add_file_reference(framework_ref)
    
    embed_build_file = embed_phase.add_file_reference(framework_ref)
    embed_build_file.settings = {
      'ATTRIBUTES' => ['CodeSignOnCopy', 'RemoveHeadersOnCopy']
    }
  end

  def save_project
    @project.save
    puts "All modifications completed successfully"
  end
end

# Usage
begin
  project_path = 'crypto-hunters-ar-game/Builds/iOS/Unity-iPhone.xcodeproj'
  modifier = XcodeProjectModifier.new(project_path)
  modifier.modify_project
rescue StandardError => e
  puts "Error: #{e.message}"
  exit 1
end

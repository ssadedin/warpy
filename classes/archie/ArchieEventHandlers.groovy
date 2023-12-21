package archie

import java.time.format.DateTimeFormatter
import java.time.OffsetDateTime
import java.time.ZoneId
import java.time.ZonedDateTime
import java.util.regex.Pattern
import java.nio.file.Paths
import java.nio.file.Path

import groovy.json.*

import bpipe.PipelineEvent
import bpipe.PipelineFile
import bpipe.Dependencies
import bpipe.Pipeline

import archie.domain.pipelines.*

import static archie.Utils.sendMessage
import static archie.utils.AnalysisUtils.createAnalysisUpdateMsgData
import static archie.apiclient.dto.AnalysisStatus.IN_PROGRESS
import static archie.apiclient.dto.AnalysisStatus.SUCCESS
import static archie.apiclient.dto.AnalysisStatus.FAILED


class ArchieEventHandlers {

    static def onPipelineStarted = { String analysis_id, String project, PipelineEvent type, String desc, Map<String, Object> details ->
        def pipeline_id = bpipe.Config.config.pid
        println "Pipeline $type event triggered, pipeline_id=$pipeline_id, desc=$desc"

        def msgContentData = createAnalysisUpdateMsgData(analysis_id, project, pipeline_id, IN_PROGRESS.name(), Collections.emptyList(), null, IN_PROGRESS.name())

        sendMessage(msgContentData)
    }

    static def onPipelineFinished = { String analysis_id, String project, PipelineEvent type, String desc, Map<String, Object> details ->
        def pipeline_id = bpipe.Config.config.pid
        println "Pipeline $type event triggered, pipeline_id=$pipeline_id, desc=$desc"

        def msgContentData = createAnalysisUpdateMsgData(analysis_id, project, pipeline_id, SUCCESS.name())
        if(!details.result) {
            println "Pipeline failed"
            def metadata = ['error': desc]
            msgContentData.status = FAILED.name()
            msgContentData.pipeline_status = FAILED.name()
            msgContentData.metadata = metadata
        }

        sendMessage(msgContentData)
    }

    static def onPipelineStageStarted = { String analysis_id, String project, List<String> batchSamples, PipelineEvent type, String desc, Map<String, Object> details ->
        def pipeline_id = bpipe.Config.config.pid
        def stageName = details.stage?.stageName
        println "Pipeline $type event triggered, pipeline_id=$pipeline_id, stageName=$stageName, desc=$desc"
    }

    static def onPipelineStageCompleted = { String analysis_id, String project, List<String> batchSamples, PipelineAssetsCollector assetsCollector, 
        PipelineEvent type, String desc, Map<String, Object> details ->

        def pipeline_id = bpipe.Config.config.pid
        def stageName = details.stage?.stageName
        println "Pipeline $type event triggered, pipeline_id=$pipeline_id, stageName=$stageName, desc=$desc"

        Closure<PipelineStageAssets> stageAssetCollector = assetsCollector.findStageAssetCollector(stageName)

        if (stageAssetCollector) {
            Path analysisDir = Paths.get(new File('.').canonicalPath)
            PipelineStageAssets stageAssets = stageAssetCollector(batchSamples, analysisDir)
            def msgContentData = createAnalysisUpdateMsgData(analysis_id, project, pipeline_id, IN_PROGRESS.name(), stageAssets.getAssets(), stageName, desc, stageAssets.getMetadata())

            sendMessage(msgContentData)
        }
    }
}
